import unittest
import os
import pathlib
import json
from typing import Tuple
import mikktspace


URI_MAP = {}


def get_accessor_bytes(path: pathlib.Path, gltf, accessor_index) -> Tuple[bytes, int]:
    match gltf['accessors'][accessor_index]:
        case {
            'bufferView': bufferview_index,
            'count': count
        }:
            match gltf['bufferViews'][bufferview_index]:
                case {
                    'buffer': buffer_index,
                    'byteOffset': byte_offset,
                    'byteLength': byte_length,
                }:
                    match gltf['buffers'][buffer_index]:
                        case {
                            'uri': uri
                        }:
                            data = URI_MAP.get(uri)
                            if not data:
                                data = (path.parent / uri).read_bytes()
                                URI_MAP[uri] = data
                            return data[byte_offset:byte_offset+byte_length], count

    raise Exception()


class TestGltf(unittest.TestCase):

    def test_gltf(self):
        path = os.environ['GLTF_SAMPLE_MODELS']
        if not path:
            return
        file = pathlib.Path(path) / "2.0/DamagedHelmet/glTF/DamagedHelmet.gltf"
        gltf = json.loads(file.read_bytes())

        mesh = gltf['meshes'][0]
        prim = mesh['primitives'][0]

        indices, indices_count = get_accessor_bytes(
            file, gltf, prim['indices'])
        match prim['attributes']:
            case {
                'POSITION': position_accessor_index,
                'NORMAL': normal_accessor_index,
                'TEXCOORD_0': uv_accessor_index,
            }:
                position, position_count = get_accessor_bytes(
                    file, gltf, position_accessor_index)
                normal, normal_count = get_accessor_bytes(
                    file, gltf, normal_accessor_index)
                uv, uv_count = get_accessor_bytes(
                    file, gltf, uv_accessor_index)
                tangent = mikktspace.gen_default(
                    position_count, position, normal, uv, indices_count, indices)
                self.assertEqual(position_count * 4 * 4, len(tangent))
            case _:
                raise Exception()


if __name__ == '__main__':
    unittest.main()
