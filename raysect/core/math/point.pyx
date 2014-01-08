# cython: language_level=3

#Copyright (c) 2014, Dr Alex Meakins, Raysect Project
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

cimport cython
from libc.math cimport sqrt
from raysect.core.math.vector cimport new_vector

cdef class Point:
    
    def __init__(self, v = (0.0, 0.0, 0.0)):
        """
        Point constructor.
        
        If no initial values are passed, Point defaults to the origin:
        [0.0, 0.0, 0.0]
        
        Any three (or more) item indexable object can be used to initialise the
        point. The x, y and z coordinates will be assigned the values of 
        the items at indexes [0, 1, 2].
        
        e.g. Point([4.0, 5.0, 6.0]) sets the x, y and z coordinates as 4.0,
        5.0 and 6.0 respectively.
        """
        
        try:
            
            self.d[0] = v[0]
            self.d[1] = v[1]
            self.d[2] = v[2]
            
        except:
            
            raise TypeError("Vector can only be initialised with an indexable object, containing numerical values, of length >= 3 items.")
    
    def __repr__(self):
        """Returns a string representation of the Point object."""

        return "Point([" + str(self.d[0]) + ", " + str(self.d[1]) + ", " + str(self.d[2]) + "])"
    
    property x:
        """The x coordinate."""
        
        def __get__(self):

            return self.d[0]

        def __set__(self, double v):

            self.d[0] = v

    property y:
        """The y coordinate."""

        def __get__(self):

            return self.d[1]

        def __set__(self, double v):

            self.d[1] = v

    property z:
        """The z coordinate."""
    
        def __get__(self):

            return self.d[2]

        def __set__(self, double v):

            self.d[2] = v
            
    def __getitem__(self, int i):
        """Returns the point coordinates by index ([0,1,2] -> [x,y,z])."""

        if i < 0 or i > 2:
            raise IndexError("Index out of range [0, 2].")
            
        return self.d[i]

    def __add__(object x, object y):
        """Point addition."""
       
        cdef Point p
        cdef _Vec3 v
        
        if isinstance(x, Point) and isinstance(y, _Vec3):

            p = <Point>x
            v = <_Vec3>y
       
        else:

            raise TypeError("Unsupported operand type. Expects a Vector, Normal or Point.")

        return new_point(p.d[0] + v.d[0],
                         p.d[1] + v.d[1],
                         p.d[2] + v.d[2])

    def __sub__(object x, object y):
        """Point subtraction."""
        
        cdef Point p
        cdef _Vec3 v
        
        if isinstance(x, Point) and isinstance(y, _Vec3):
            
            p = <Point>x
            v = <_Vec3>y

            return new_point(p.d[0] - v.d[0],
                             p.d[1] - v.d[1],
                             p.d[2] - v.d[2])
        
        
        else:

            raise TypeError("Unsupported operand type. Expects a Vector, Normal or Point.")

    cpdef Vector vector_to(self, Point p):
        """
        Returns a vector from this point to the passed point.
        """

        return new_vector(p.d[0] - self.d[0],
                          p.d[1] - self.d[1],
                          p.d[2] - self.d[2])
    
    cpdef double distance_to(self, Point p):
        """
        Returns the distance between this point and the passed point.
        """
    
        cdef double x, y, z
        x = p.d[0] - self.d[0]
        y = p.d[1] - self.d[1]
        z = p.d[2] - self.d[2]
        return sqrt(x*x + y*y + z*z)

    # cython api ---------------------------------------------------------------

    # x coordinate getters/setters
    cdef inline double get_x(self):
        
        return self.d[0]
    
    cdef inline void set_x(self, double v):
        
        self.d[0] = v

    # y coordinate getters/setters
    cdef inline double get_y(self):
        
        return self.d[1]
    
    cdef inline void set_y(self, double v):
        
        self.d[1] = v        
        
    # z coordinate getters/setters
    cdef inline double get_z(self):
        
        return self.d[2]
    
    cdef inline void set_z(self, double v):
        
        self.d[2] = v
       