# cython: language_level=3

# Copyright (c) 2014-2016, Dr Alex Meakins, Raysect Project
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     1. Redistributions of source code must retain the above copyright notice,
#        this list of conditions and the following disclaimer.
#
#     2. Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#
#     3. Neither the name of the Raysect Project nor the names of its
#        contributors may be used to endorse or promote products derived from
#        this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

from raysect.optical.observer.base.processor cimport PixelProcessor


cdef class Pipeline0D:

    cpdef object initialise(self, double min_wavelength, double max_wavelength, int spectral_bins, list spectral_slices)

    cpdef PixelProcessor pixel_processor(self, int slice_id)

    cpdef object update(self, int slice_id, tuple packed_result, int samples)

    cpdef object finalise(self)


cdef class Pipeline1D:

    cpdef object initialise(self, tuple pixels, int pixel_samples, double min_wavelength, double max_wavelength, int spectral_bins, list spectral_slices)

    cpdef PixelProcessor pixel_processor(self, int pixel, int slice_id)

    cpdef object update(self, int pixel, int slice_id, tuple packed_result)

    cpdef object finalise(self)


cdef class Pipeline2D:

    cpdef object initialise(self, tuple pixels, int pixel_samples, double min_wavelength, double max_wavelength, int spectral_bins, list spectral_slices)

    cpdef PixelProcessor pixel_processor(self, int x, int y, int slice_id)

    cpdef object update(self, int x, int y, int slice_id, tuple packed_result)

    cpdef object finalise(self)
