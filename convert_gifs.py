import imageio.v3 as iio
import os
import sys

files = {
    'student.mp4': 'role_student.gif',
    'explorer.mp4': 'role_explorer.gif',
    'mentor.mp4': 'role_mentor.gif'
}

for src_name, dst_name in files.items():
    src = os.path.join(r"c:\src\VERASSO", src_name)
    dst = os.path.join(r"c:\src\VERASSO\assets\images", dst_name)
    
    if os.path.exists(src):
        try:
            print(f"Converting {src_name} to {dst_name}...")
            # read mp4 frames
            frames = iio.imread(src)
            # determine optimal fps if available, else default to 15
            fps = 15
            
            # create GIF, loop=0 means loop infinitely
            # Try setting fps parameter, if not supported fallback to duration
            iio.imwrite(dst, frames, extension=".gif", loop=0, duration=1000/fps)
            print(f"Successfully created {dst_name}!")
        except Exception as e:
            print(f"Error converting {src_name}: {e}")
    else:
        print(f"Warning: Source file {src} not found.")

sys.exit(0)
