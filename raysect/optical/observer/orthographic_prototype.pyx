# Copyright (c) 2016, Dr Alex Meakins, Raysect Project
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

from raysect.optical.observer.old.point_generator import Rectangle
from raysect.optical.observer.sampler2d import FullFrameSampler2D
from raysect.optical.observer.pipeline import RGBPipeline2D

from raysect.optical.observer.old.vector_generators cimport VectorGenerator
from raysect.optical.observer.old.vector_generators import SingleRay
from raysect.core cimport Point3D, new_point3d, Vector3D, new_vector3d, translate
from raysect.optical cimport Ray
from libc.math cimport M_PI as pi, tan
from raysect.optical.observer.base cimport Observer2D


cdef class OrthographicCamera(Observer2D):
    """
    A camera observing an orthogonal (orthographic) projection of the scene, avoiding perspective effects.

    Arguments and attributes are inherited from the base Imaging sensor class.

    :param double width: width of the orthographic area to observe in meters, the height is deduced from the 'pixels'
       attribute.
    """

    cdef:
        double image_delta, image_start_x, image_start_y, _width
        VectorGenerator _vector_generator

    def __init__(self, pixels, width=1, parent=None, transform=None, name=None, pipelines=None):

        pipelines = pipelines or [RGBPipeline2D()]

        super().__init__(pixels, FullFrameSampler2D(), pipelines,
                         parent=parent, transform=transform, name=name)

        self.width = width
        self._vector_generator = SingleRay()
        self._update_image_geometry()

    cdef inline object _update_image_geometry(self):

        self.image_delta = self._width / self._pixels[0]
        self.image_start_x = 0.5 * self._pixels[0] * self.image_delta
        self.image_start_y = 0.5 * self._pixels[1] * self.image_delta
        self._point_generator = Rectangle(self.image_delta, self.image_delta)

    @property
    def width(self):
        return self._width

    @width.setter
    def width(self, width):
        if width <= 0:
            raise ValueError("width can not be less than or equal to 0 meters.")
        self._width = width
        self._update_image_geometry()

    cpdef list _generate_rays(self, tuple pixel_id, Ray template, int ray_count):

        cdef:
            int ix, iy
            double pixel_x, pixel_y
            list points, rays
            Point3D pixel_centre, point, origin
            Vector3D direction
            Ray ray

        # unpack
        ix, iy = pixel_id

        # generate pixel transform
        pixel_x = self.image_start_x - self.image_delta * ix
        pixel_y = self.image_start_y - self.image_delta * iy
        to_local = translate(pixel_x, pixel_y, 0)

        # generate origin and direction vectors
        origin_points = self._point_generator(self._pixel_samples)
        direction_vectors = self._vector_generator(self._pixel_samples)

        # assemble rays
        rays = []
        for origin, direction in zip(origin_points, direction_vectors):

            # transform to local space from pixel space
            origin = origin.transform(to_local)
            direction = direction.transform(to_local)

            ray = template.copy(origin, direction)

            # rays fired along normal hence projected area weight is 1.0
            rays.append((ray, 1.0))

        return rays

    cpdef double _pixel_etendue(self, tuple pixel_id):
        return 1.0


