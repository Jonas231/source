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

import numpy as np
cimport numpy as np
from raysect.core.boundingbox cimport BoundingBox2D, new_boundingbox2d
from raysect.core.math.function.function2d cimport Function2D
from raysect.core.math.point cimport Point2D, new_point2d
from raysect.core.math.spatial.kdtree2d cimport KDTree2DCore, Item2D
cimport cython

# bounding box is padded by a small amount to avoid numerical accuracy issues
DEF BOX_PADDING = 1e-6

# convenience defines
DEF V1 = 0
DEF V2 = 1
DEF V3 = 2

DEF X = 0
DEF Y = 1


cdef class _MeshKDTree(KDTree2DCore):

    def __init__(self, object vertices not None, object triangles not None):

        self._vertices = vertices
        self._triangles = triangles

        # check dimensions are correct
        if vertices.ndim != 2 or vertices.shape[1] != 2:
            raise ValueError("The vertex array must have dimensions Nx2.")

        if triangles.ndim != 2 or triangles.shape[1] != 3:
            raise ValueError("The triangle array must have dimensions Mx3.")

        # check triangles contains only valid indices
        invalid = (triangles[:, 0:3] < 0) | (triangles[:, 0:3] >= vertices.shape[0])
        if invalid.any():
            raise ValueError("The triangle array references non-existent vertices.")

        # kd-Tree init
        items = []
        for triangle in range(self._triangles.shape[0]):
            items.append(Item2D(triangle, self._generate_bounding_box(triangle)))
        super().__init__(items, max_depth=0, min_items=1, hit_cost=50.0, empty_bonus=0.2)

        # todo: (possible enhancement) check if triangles are overlapping?
        # (any non-owned vertex lying inside another triangle)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef inline BoundingBox2D _generate_bounding_box(self, np.int32_t triangle):
        """
        Generates a bounding box for the specified triangle.

        A small degree of padding is added to the bounding box to provide the
        conservative bounds required by the watertight mesh algorithm.

        :param triangle: Triangle array index.
        :return: A BoundingBox2D object.
        """

        cdef:
            double[:, ::1] vertices
            np.int32_t[:, ::1] triangles
            np.int32_t i1, i2, i3
            BoundingBox2D bbox

        # assign locally to avoid repeated memory view validity checks
        vertices = self._vertices
        triangles = self._triangles

        i1 = triangles[triangle, V1]
        i2 = triangles[triangle, V2]
        i3 = triangles[triangle, V3]

        bbox = new_boundingbox2d(
            new_point2d(
                min(vertices[i1, X], vertices[i2, X], vertices[i3, X]),
                min(vertices[i1, Y], vertices[i2, Y], vertices[i3, Y]),
            ),
            new_point2d(
                max(vertices[i1, X], vertices[i2, X], vertices[i3, X]),
                max(vertices[i1, Y], vertices[i2, Y], vertices[i3, Y]),
            ),
        )
        bbox.pad(max(BOX_PADDING, bbox.largest_extent() * BOX_PADDING))

        return bbox

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef bint _is_contained_leaf(self, np.int32_t id, Point2D point):

        cdef:
            np.int32_t index, triangle, i1, i2, i3
            double alpha, beta, gamma

        # cache locally to avoid pointless memory view checks
        triangles = self._triangles

        # identify the first triangle that contains the point, if any
        for index in range(self._nodes[id].count):

            # obtain vertex indices
            triangle = self._nodes[id].items[index]
            i1 = triangles[triangle, V1]
            i2 = triangles[triangle, V2]
            i3 = triangles[triangle, V3]

            self._calc_barycentric_coords(i1, i2, i3, point.x, point.y, &alpha, &beta, &gamma)
            if self._hit_triangle(alpha, beta, gamma):

                # store id of triangle hit
                self.triangle_id = index
                return True

        return False

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.cdivision(True)
    cdef inline void _calc_barycentric_coords(self, np.int32_t i1, np.int32_t i2, np.int32_t i3, double px, double py, double *alpha, double *beta, double *gamma) nogil:

        cdef:
            np.int32_t[:, ::1] triangles
            double[:, ::1] vertices
            double v1x, v2x, v3x, v1y, v2y, v3y
            double x1, x2, x3, y1, y2, y3
            double norm

        # cache locally to avoid pointless memory view checks
        vertices = self._vertices

        # obtain the vertex coords
        v1x = vertices[i1, X]
        v1y = vertices[i1, Y]

        v2x = vertices[i2, X]
        v2y = vertices[i2, Y]

        v3x = vertices[i3, X]
        v3y = vertices[i3, Y]

        # compute common values
        x1 = v1x - v3x
        x2 = v3x - v2x
        x3 = px - v3x

        y1 = v1y - v3y
        y2 = v2y - v3y
        y3 = py - v3y

        norm = 1 / (x1 * y2 + y1 * x2)

        # compute barycentric coordinates
        alpha[0] = norm * (x2 * y3 + y2 * x3)
        beta[0] = norm * (x1 * y3 - y1 * x3)
        gamma[0] = 1.0 - alpha[0] - beta[0]

    cdef inline bint _hit_triangle(self, double alpha, double beta, double gamma) nogil:

        # Point is inside triangle if all coordinates lie in range [0, 1]
        # if all are > 0 then none can be > 1 from definition of barycentric coordinates
        return alpha >= 0 and beta >= 0 and gamma >= 0


cdef class Discrete2DMesh(Function2D):
    # """
    # Linear interpolator for data on a 2d ungridded tri-poly mesh.
    #
    # The mesh is specified as a set of 2D vertices supplied as an Nx2 numpy
    # array or a suitably sized sequence that can be converted to a numpy array.
    #
    # A data array of length N, containing a value for each vertex, holds the
    # data to be interpolated across the mesh.
    #
    # The mesh triangles are defined with a Mx3 array where the three values are
    # indices into the vertex array that specify the triangle vertices. The
    # mesh must not contain overlapping triangles. Supplying a mesh with
    # overlapping triangles will result in undefined behaviour.
    #
    # By default, requesting a point outside the bounds of the mesh will cause
    # a ValueError exception to be raised. If this is not desired the limit
    # attribute (default True) can be set to False. When set to False, a default
    # value will be returned for any point lying outside the mesh. The value
    # return can be specified by setting the default_value attribute (default is
    # 0.0).
    #
    # To optimise the lookup of triangles, the interpolator builds an
    # acceleration structure (a KD-Tree) from the specified mesh data. Depending
    # on the size of the mesh, this can be quite slow to construct. If the user
    # wishes to interpolate a number of different data sets across the same mesh
    # - for example: temperature and density data that are both defined on the
    # same mesh - then the user can use the instance() method on an existing
    # interpolator to create a new interpolator. The new interpolator will shares
    # a copy of the internal acceleration data. The vertex_data, limit and
    # default_value can be customised for the new instance. See instance(). This
    # will avoid the cost in memory and time of rebuilding an identical
    # acceleration structure.
    #
    #     An array of vertex coordinates with shape (num of vertices, 2). For each vertex
    #     # there must be a (u, v) coordinate.
    #     # :param ndarray vertex_data: An array of data points at each vertex with shape (num of vertices).
    #     # :param ndarray triangles: An array of triangles with shape (num of triangles, 3). For each triangle, there must
    #     # be three indices that identify the three corresponding vertices in vertex_coords that make up this triangle.
    #
    #
    # :param vertex_coords: An array of vertex coordinates (x, y) with shape Nx2.
    # :param vertex_data: An array containing data for each vertex of shape Nx1.
    # :param triangles: An array of vertex indices defining the mesh triangles, with shape Mx3.
    # :param limit: Raise an exception outside mesh limits - True (default) or False.
    # :param default_value: The value to return outside the mesh limits if limit is set to False.
    # """

    def __init__(self, object vertex_coords not None, object triangles not None, object triangle_data not None, bint limit=True, double default_value=0.0):

        # use numpy arrays to store data internally
        vertex_coords = np.array(vertex_coords, dtype=np.float64)
        triangles = np.array(triangles, dtype=np.int32)
        triangle_data = np.array(triangle_data, dtype=np.float64)

        # validate triangle_data
        if triangle_data.ndim != 1 or triangle_data.shape[0] != triangles.shape[0]:
            raise ValueError("triangle_data dimensions ({}) are incompatible with the number of triangles ({}).".format(triangle_data.shape[0], triangles.shape[0]))

        # build kdtree
        self._kdtree = _MeshKDTree(vertex_coords, triangles)

        self._triangle_data = triangle_data
        self._default_value = default_value
        self._limit = limit

    @classmethod
    def instance(cls, Discrete2DMesh instance not None, object triangle_data=None, object limit=None, object default_value=None):
        # """
        # Creates a new interpolator instance from an existing interpolator instance.
        #
        # The new interpolator instance will share the same internal acceleration
        # data as the original interpolator. The vertex_data, limit and default_value
        # settings of the new instance can be redefined by setting the appropriate
        # attributes. If any of the attributes are set to None (default) then the
        # value from the original interpolator will be copied.
        #
        # This method should be used if the user has multiple sets of vertex_data
        # that lie on the same mesh geometry. Using this methods avoids the
        # repeated rebuilding of the mesh acceleration structures by sharing the
        # geometry data between multiple interpolator objects.
        #
        # :param instance: Interpolator2DMesh object.
        # :param vertex_data: An array containing data for each vertex of shape Nx1 (default None).
        # :param limit: Raise an exception outside mesh limits - True (default) or False (default None).
        # :param default_value: The value to return outside the mesh limits if limit is set to False (default None).
        # :return: An Interpolator2DMesh object.
        # """

        cdef Discrete2DMesh m

        # copy source data
        m = Discrete2DMesh.__new__(Discrete2DMesh)
        m._kdtree = instance._kdtree

        # do we have replacement triangle data?
        if triangle_data is None:
            m._triangle_data = instance._triangle_data
        else:
            m._triangle_data = np.array(triangle_data, dtype=np.float64)
            if m._triangle_data.ndim != 1 or m._triangle_data.shape[0] != instance._triangle_data.shape[0]:
                raise ValueError("triangle_data dimensions ({}) are incompatible with the number of triangles ({}).".format(m._triangle_data.shape[0], instance._triangle_data.shape[0]))

        # do we have a replacement limit check setting?
        if limit is None:
            m._limit = instance._limit
        else:
            m._limit = limit

        # do we have a replacement default value?
        if default_value is None:
            m._default_value = instance._default_value
        else:
            m._default_value = default_value

        return m

    @cython.boundscheck(False)
    @cython.wraparound(False)
    cdef double evaluate(self, double x, double y) except *:

        cdef:
            np.int32_t triangle_id

        if self._kdtree.is_contained(new_point2d(x, y)):
            triangle_id = self._kdtree.triangle_id
            return self._triangle_data[triangle_id]

        if not self._limit:
            return self._default_value

        raise ValueError("Requested value outside mesh bounds.")
