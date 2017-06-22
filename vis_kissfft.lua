-- Sonique Visualizer FFI plugin
local ffi = require("ffi")
local bit = require("bit")
local kiss_fft = ffi.load("sonique_visualizer/kiss_fft.dll")
local love = love

ffi.cdef [[
typedef struct 
{
	unsigned long	MillSec;			// Sonique sets this to the time stamp of end this block of data
	signed char		Waveform[2][512];	// Sonique sets this to the PCM data being outputted at this time
	unsigned char	Spectrum[2][256];	// Sonique sets this to a lowfidely version of the spectrum data
										//   being outputted at this time
} VisData;

typedef struct _VisInfo
{
	unsigned long Version;				// 1 = supports Clicked(x,y,buttons)

	char	*PluginName;				// Set to the name of the plugin
	long	lRequired;					// Which vis data this plugin requires (set to a combination of
										//   the VI_WAVEFORM, VI_SPECTRUM and SONIQEUVISPROC flags)

	void	(*Initialize)(void);		// Called some time before your plugin is asked to render for
										// the first time
	int		(*Render)( unsigned long *Video, int width, int height, int pitch, VisData* pVD);
										// Called for each frame. Pitch is in pixels and can be negative.
										// Render like this:
										// for (y = 0; y < height; y++)
										// {
										//    for (x = 0; x < width; x++)
										//       Video[x] = <pixel value>;
										//	  Video += pitch;
										// }
										//				OR
										// void PutPixel(int x, int y, unsigned long Pixel)
										// {
										//    _ASSERT( x >= 0 && x < width && y >= 0 && y < height );
										//	  Video[y*pitch+x] = Pixel;
										// }
	int		(*SaveSettings)( char* FileName );
										// Use WritePrivateProfileString to save settings when this is called
										// Example:
										// WritePrivateProfileString("my plugin", "brightness", "3", FileName);
	int		(*OpenSettings)( char* FileName );
										// Use GetPrivateProfileString similarly:
										// char BrightnessBuffer[256];
										// GetPrivateProfileString("my plugin", "brightness", "3", BrightnessBuffer, sizeof(BrightnessBuffer), FileName);

		int	(*Deinit)( );
		int	(*Clicked)( int x, int y, int buttons );

} VisInfo;

VisInfo* QueryModule(void);

typedef struct {
    float r;
    float i;
}kiss_fft_cpx;

typedef struct kiss_fft_state* kiss_fft_cfg;

kiss_fft_cfg kiss_fft_alloc(int nfft,int inverse_fft,void * mem,size_t * lenmem); 
void kiss_fft(kiss_fft_cfg cfg,const kiss_fft_cpx *fin,kiss_fft_cpx *fout);
void kiss_fft_stride(kiss_fft_cfg cfg,const kiss_fft_cpx *fin,kiss_fft_cpx *fout,int fin_stride);
void kiss_fft_cleanup(void);
int kiss_fft_next_fast_size(int n);
]]


local function getsample_safe(sound_data, pos)
	local _, sample = pcall(sound_data.getSample, sound_data, pos)
	
	if _ == false then
		return 0
	end
	
	return sample
end


local function getsample_size(audio, pos, size, channels)
	size = size or 1
	
	local sample_list = {}
	
	if not(audio) then
		for i = 1, size do
			sample_list[#sample_list + 1] = {0, 0}
		end
		
		return sample_list
	end
	
	if not(channels) then
		channels = audio:getChannels()
	end
	
	if channels == 1 then
		for i = pos, pos + size - 1 do
			-- Mono
			local sample = getsample_safe(audio, i)
			
			sample_list[#sample_list + 1] = {sample, sample}
		end
	elseif channels == 2 then
		for i = pos, pos + size - 1 do
			-- Stereo
			sample_list[#sample_list + 1] = {
				getsample_safe(audio, i * 2),
				getsample_safe(audio, i * 2 + 1),
			}
		end
	end
	
	return sample_list
end

local SoniqueVis = {
	_vislist = setmetatable({}, {
		__mode = "v",
		__index = function(_, var)
			local this = {}
			
			this.VisDLL = ffi.load(var)
			this.VisInfo = this.VisDLL.QueryModule()
			this.Name = this.VisInfo.PluginName ~= nil and ffi.string(this.VisInfo.PluginName) or ""
			this.NeedWaveform = bit.band(this.VisInfo.lRequired, 1) > 0
			this.NeedSpectrum = bit.band(this.VisInfo.lRequired, 2) > 0
			this.HasExtension = this.VisInfo.Version == 1
			
			print("Visualizer load")
			print("Name", this.Name)
			print("NeedWaveform", this.NeedWaveform)
			print("NeedSpectrum", this.NeedSpectrum)
			print("HasExtension", this.HasExtension)
			
			this.VisInfo.Initialize()
			this.VisInfo.OpenSettings(ffi.cast("char*", love.filesystem.getSource().."/"..var..".txt"))
			
			_[var] = this
			return this
		end,
	})
}
local visobj = {Type = "SoniqueVisualizer"}
local visobjmt = {__index = visobj}

function SoniqueVis.New(visname, x, y)
	local this = {}
	
	this.VisObj = SoniqueVis._vislist[visname]
	this.ImageData = love.image.newImageData(x, y)
	this.ImageDataPtr = ffi.cast("unsigned long*", this.ImageData:getPointer())
	this.X, this.Y = x, y
	this.Image = love.graphics.newImage(this.ImageData)
	this.VisData = ffi.new("VisData[1]")
	print("VisData pointer", this.VisData)
	
	-- Init KissFFT
	local sizetemp = ffi.new("size_t[1]")
	kiss_fft.kiss_fft_alloc(512, 0, nil, sizetemp)
	
	this.KissFFTInternal = ffi.new("uint8_t[?]", tonumber(sizetemp[0]))
	this.KissFFT = kiss_fft.kiss_fft_alloc(512, 0, this.KissFFTInternal, sizetemp)
	
	return setmetatable(this, visobjmt)
end

function visobj.Link(this, audio, sounddata)
	this.AudioSrc = audio
	this.SoundData = sounddata
	this.AudioChannels = sounddata:getChannels()
	
	return this
end

local whole_sample_buffer = ffi.new("kiss_fft_cpx[2048]")
local reusable_sample = {whole_sample_buffer, whole_sample_buffer + 512}
local reusable_sample2 = {whole_sample_buffer + 1024, whole_sample_buffer + 1536}
local graphics_draw = love.graphics.draw
function visobj.Update(this, dt, premul1000)
	assert(this.AudioSrc and this.SoundData, "Link Source and SoundData first!")
	
	local sampledur = this.AudioSrc:tell("samples")
	local samples = getsample_size(this.AudioSrc:isPlaying() and this.SoundData or nil, sampledur, 512, this.AudioChannels)
	
	this.VisData[0].MillSec = this.AudioSrc:tell() * 1000
	--this.VisData[0].MillSec = 33
	
	-- Set waveform
	if this.VisObj.NeedWaveform then
		for i = 0, 511 do
			for j = 0, 1 do
				this.VisData[0].Waveform[j][i] = samples[i + 1][j + 1] * 64
			end
		end
	end
	
	-- FFT
	if this.VisObj.NeedSpectrum then
		ffi.fill(whole_sample_buffer, ffi.sizeof("kiss_fft_cpx") * 2048, 0)
		
		for i = 0, 511 do
			for j = 1, 2 do
				reusable_sample[j][i].r = samples[i + 1][j]
			end
		end
		
		local spec = reusable_sample2
		kiss_fft.kiss_fft(this.KissFFT, reusable_sample[1], reusable_sample2[1])
		kiss_fft.kiss_fft(this.KissFFT, reusable_sample[2], reusable_sample2[2])
		
		this.VisData[0].Spectrum[0][0] = math.min(spec[1][0].r * 256 + 0.5, 255)
		this.VisData[0].Spectrum[1][0] = math.min(spec[2][0].r * 256 + 0.5, 255)
		for i = 0, 255 do
			for j = 0, 1 do
				local a = spec[j + 1][i]
				
				this.VisData[0].Spectrum[j][i] = math.min(math.sqrt((a.r / 256) ^ 2 + (a.i / 256) ^ 2) * 512 + 0.5, 255)
				--this.VisData[0].Spectrum[j][i] = math.min(math.sqrt(a.r * a.r + a.i * a.i) + 0.5, 255)
			end
		end
	end
	
	this.VisObj.VisInfo.Render(this.ImageDataPtr, this.X, this.Y, this.X, this.VisData)
	this.Image:refresh()
end

function visobj.Draw(this, ...)
	graphics_draw(this.Image, ...)
end

function visobj.Click(this, x, y, button)
	if this.VisObj.HasExtension then
		-- It's up to user to calculate correct X and Y position
		print(this.VisObj.VisInfo.Clicked(x, y, button))
	end
end

function love.graphics.draw(obj, ...)
	if type(obj) == "table" and obj.Type == "SoniqueVisualizer" then
		obj = obj.Image
	end
	
	graphics_draw(obj, ...)
end

return SoniqueVis
