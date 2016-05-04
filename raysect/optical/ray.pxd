# cython: language_level=3

# Copyright (c) 2014, Dr Alex Meakins, Raysect Project
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

from raysect.core.ray cimport Ray as CoreRay
from raysect.core.math.point cimport Point3D
from raysect.core.math.vector cimport Vector3D
from raysect.optical.scenegraph.world cimport World
from raysect.core.scenegraph.primitive cimport Primitive
from raysect.optical.spectrum cimport Spectrum
from raysect.core.boundingbox cimport BoundingBox3D
from raysect.core.intersection cimport Intersection


cdef class Ray(CoreRay):

    cdef:
        public bint importance_sampling
        int _num_samples
        double _min_wavelength
        double _max_wavelength
        double _extinction_prob
        int _min_depth
        int _max_depth
        public int depth
        readonly int ray_count
        Ray _primary_ray

    cpdef Spectrum new_spectrum(self)
    cpdef Spectrum trace(self, World world, bint keep_alive=*)
    cpdef Spectrum sample(self, World world, int samples)
    cpdef Ray spawn_daughter(self, Point3D origin, Vector3D direction)
    cdef inline int get_num_samples(self)
    cdef inline double get_min_wavelength(self)
    cdef inline double get_max_wavelength(self)
    cdef inline Spectrum _sample_surface(self, Intersection intersection, World world)
    cdef inline Spectrum _sample_volumes(self, Spectrum spectrum, Intersection intersection, World world)


cdef inline Ray new_ray(Point3D origin, Vector3D direction,
             double min_wavelength, double max_wavelength, int num_samples,
             double max_distance,
             double extinction_prob, int min_depth, int max_depth,
             bint importance_sampling):

    cdef Ray ray

    ray = Ray.__new__(Ray)
    ray.origin = origin
    ray.direction = direction
    ray.max_distance = max_distance
    ray._num_samples = num_samples
    ray._min_wavelength = min_wavelength
    ray._max_wavelength = max_wavelength
    ray.importance_sampling = importance_sampling

    ray._extinction_prob = extinction_prob
    ray._min_depth = min_depth
    ray._max_depth = max_depth
    ray.depth = 0

    ray.ray_count = 0
    ray._primary_ray = None

    return ray

