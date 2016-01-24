
# External imports
from matplotlib.pyplot import *
import time

# Internal imports
from raysect.optical import World, translate, rotate, Point3D, Vector3D, Normal3D, Ray, d65_white, ConstantSF, InterpolatedSF, Node
from raysect.optical.observer.cameras import PinholeCamera
from raysect.optical.material.dielectric import Sellmeier, Dielectric
from raysect.optical.material.emitter import UniformVolumeEmitter
from raysect.optical.material.absorber import AbsorbingSurface
from raysect.primitive import Box, Subtract
from raysect.primitive.mesh import Mesh
from raysect.primitive.mesh import import_obj
from raysect.optical.library import schott


"""
A Diamond Stanford Bunny on an Illuminated Glass Pedestal
---------------------------------------------------------

Bunny model source:
  Stanford University Computer Graphics Laboratory
  http://graphics.stanford.edu/data/3Dscanrep/
  Converted to obj format using MeshLab
"""

# DIAMOND MATERIAL
diamond = Dielectric(Sellmeier(0.3306, 4.3356, 0.0, 0.1750**2, 0.1060**2, 0.0), ConstantSF(1.0))

world = World()

# BUNNY
# mesh = import_obj("./resources/stanford_bunny.obj", scaling=1, parent=world,
#                   transform=translate(0, 0, 0)*rotate(165, 0, 0), material=diamond)  # material=schott("LF5G19")

mesh = Mesh.from_file("./resources/stanford_bunny.rsm", parent=world,
                  transform=translate(0, 0, 0)*rotate(165, 0, 0), material=diamond)

# LIGHT BOX
padding = 1e-5
enclosure_thickness = 0.001 + padding
glass_thickness = 0.003

light_box = Node(parent=world)

enclosure_outer = Box(Point3D(-0.10 - enclosure_thickness, -0.02 - enclosure_thickness, -0.10 - enclosure_thickness),
                      Point3D(0.10 + enclosure_thickness, 0.0, 0.10 + enclosure_thickness))
enclosure_inner = Box(Point3D(-0.10 - padding, -0.02 - padding, -0.10 - padding),
                      Point3D(0.10 + padding, 0.001, 0.10 + padding))
enclosure = Subtract(enclosure_outer, enclosure_inner, material=AbsorbingSurface(), parent=light_box)

glass_outer = Box(Point3D(-0.10, -0.02, -0.10),
                  Point3D(0.10, 0.0, 0.10))
glass_inner = Box(Point3D(-0.10 + glass_thickness, -0.02 + glass_thickness, -0.10 + glass_thickness),
                  Point3D(0.10 - glass_thickness, 0.0 - glass_thickness, 0.10 - glass_thickness))
glass = Subtract(glass_outer, glass_inner, material=schott("N-BK7"), parent=light_box)

emitter = Box(Point3D(-0.10 + glass_thickness + padding, -0.02 + glass_thickness + padding, -0.10 + glass_thickness + padding),
              Point3D(0.10 - glass_thickness - padding, 0.0 - glass_thickness - padding, 0.10 - glass_thickness - padding),
              material=UniformVolumeEmitter(d65_white, 50), parent=light_box)

# CAMERA
ion()
camera = PinholeCamera(fov=40, parent=world, transform=translate(0, 0.16, -0.4) * rotate(0, -12, 0))
camera.ray_min_depth = 3
camera.ray_max_depth = 500
camera.ray_extinction_prob = 0.01
camera.pixel_samples = 250
camera.rays = 10
camera.spectral_samples = 2
camera.pixels = (1024, 1024)
camera.display_progress = True
camera.display_update_time = 15
camera.sub_sample = True
camera.observe()

ioff()
camera.save("stanford_bunny_{}.png".format(time.strftime("%Y-%m-%d_%H-%M-%S")))
camera.display()
show()

