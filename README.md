LOVE2D Sonique Visualizer
=========================

Another proof-of-concept of loading Sonique Visualizer plugin to LOVE2D and display it.  
Well, not all visualizer is supported. Some might works, some might simply display black screen.

**Windows 32-bit is only the supported platform! Windows 64-bit or any other OS is not supported!**

Usage
-----

Clone first

    git clone https://github.com/MikuAuahDark/sonique_visualizer

Download sonique visualizers [here](http://aimp.ru/index.php?do=catalog&rec_id=36) and extract only the DLL to `sonique_visualizer` folder.  
There's one default visualizer which needs to be extracted. It's "Rabbit Hole".

Run it with LOVE2D

    love sonique_visualizer audiofile.wav <visualizer_name>

If no `visualizer_name` specificed, it defaults to "Rabbit Hole"

Screenshot
----------

![The Rabbit Hole TEST v1.1](https://i.imgur.com/tviWg5r.png)

License
-------

File `main.lua`, `vis.lua`, and `vis_kissfft.lua` is released under public domain. **But please see disclaimer below!**

Disclaimer
----------

* Sonique and it's plugins belongs to their respective owner.

* LuaFFT by Benjamin von Ardenne. See `luafft.lua` for more details.

### KissFFT

KissFFT is licensd under revised BSD license.

> Copyright (c) 2003-2010 Mark Borgerding
> 
> All rights reserved.
> 
> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
> 
> 	* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
> 	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
> 	* Neither the author nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.
> 
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

KissFFT.dll compiled under MSVC 17.0 with this command:

    cl /MT /LD kiss_fft.c /link /DEF:def.txt

where def.txt contains:

	EXPORTS
		kiss_fft_alloc
		kiss_fft
		kiss_fft_stride
		kiss_fft_cleanup
		kiss_fft_next_fast_size
