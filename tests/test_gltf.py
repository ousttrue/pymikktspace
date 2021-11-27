import unittest
import os
import pathlib
import json
from typing import NamedTuple, Tuple, Type
import ctypes
import mikktspace


URI_MAP = {}


class TypedBytes(NamedTuple):
    data: bytes
    element_type: Type[ctypes._SimpleCData]
    element_count: int = 1

    def get_stride(self) -> int:
        return ctypes.sizeof(self.element_type) * self.element_count

    def get_count(self) -> int:
        return len(self.data) // self.get_stride()

    def get(self, index: int) -> bytes:
        stride = self.get_stride()
        begin = stride * index
        return self.data[begin:begin+stride]


def get_ctype(component_type) -> Type[ctypes._SimpleCData]:
    match component_type:
        case 5123:
            return ctypes.c_ushort
        case 5126:
            return ctypes.c_float

        case _:
            raise Exception()


def get_type_count(type) -> int:
    match type:
        case "SCALAR": return 1
        case "VEC2": return 2
        case "VEC3": return 3
        case "VEC4": return 4
        case "MAT2": return 4
        case "MAT3": return 9
        case "MAT4": return 16
        case _:
            raise Exception()


def get_accessor_bytes(path: pathlib.Path, gltf, accessor_index) -> TypedBytes:
    match gltf['accessors'][accessor_index]:
        case {
            'bufferView': bufferview_index,
            'count': count,
            'componentType': component_type,
            'type': type
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
                            slice = data[byte_offset:byte_offset+byte_length]
                            return TypedBytes(slice, get_ctype(component_type), get_type_count(type))

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

        indices = get_accessor_bytes(
            file, gltf, prim['indices'])
        match prim['attributes']:
            case {
                'POSITION': position_accessor_index,
                'NORMAL': normal_accessor_index,
                'TEXCOORD_0': uv_accessor_index,
            }:
                position = get_accessor_bytes(
                    file, gltf, position_accessor_index)
                normal = get_accessor_bytes(
                    file, gltf, normal_accessor_index)
                uv = get_accessor_bytes(
                    file, gltf, uv_accessor_index)
                tangent = mikktspace.gen_default(memoryview(indices.data).cast(indices.element_type._type_),
                                                 memoryview(
                                                     position.data).cast('f'),
                                                 memoryview(
                                                     normal.data).cast('f'),
                                                 memoryview(uv.data).cast('f'))
                self.assertEqual(position.get_count() * 4, len(tangent))

                # debug
                # pathlib.Path('tmp.bin').write_text(
                #     json.dumps([x for x in tangent]))
            case _:
                raise Exception()


if __name__ == '__main__':
    unittest.main()
