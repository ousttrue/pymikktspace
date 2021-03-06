cdef extern from "mikktspace.h":
    ctypedef int tbool;

    struct SMikkTSpaceInterface:
        # Returns the number of faces (triangles/quads) on the mesh to be processed.
        int (*m_getNumFaces)(const SMikkTSpaceContext * pContext)

        # Returns the number of vertices on face number iFace
        # iFace is a number in the range {0, 1, ..., getNumFaces()-1}
        int (*m_getNumVerticesOfFace)(const SMikkTSpaceContext * pContext, const int iFace)

        # returns the position/normal/texcoord of the referenced face of vertex number iVert.
        # iVert is in the range {0,1,2} for triangles and {0,1,2,3} for quads.
        void (*m_getPosition)(const SMikkTSpaceContext * pContext, float fvPosOut[], const int iFace, const int iVert)
        void (*m_getNormal)(const SMikkTSpaceContext * pContext, float fvNormOut[], const int iFace, const int iVert)
        void (*m_getTexCoord)(const SMikkTSpaceContext * pContext, float fvTexcOut[], const int iFace, const int iVert)

        # either (or both) of the two setTSpace callbacks can be set.
        # The call-back m_setTSpaceBasic() is sufficient for basic normal mapping.

        # This function is used to return the tangent and fSign to the application.
        # fvTangent is a unit length vector.
        # For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
        # bitangent = fSign * cross(vN, tangent);
        # Note that the results are returned unindexed. It is possible to generate a new index list
        # But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
        # DO NOT! use an already existing index list.
        void (*m_setTSpaceBasic)(const SMikkTSpaceContext * pContext, const float fvTangent[], const float fSign, const int iFace, const int iVert)

        # This function is used to return tangent space results to the application.
        # fvTangent and fvBiTangent are unit length vectors and fMagS and fMagT are their
        # true magnitudes which can be used for relief mapping effects.
        # fvBiTangent is the "real" bitangent and thus may not be perpendicular to fvTangent.
        # However, both are perpendicular to the vertex normal.
        # For normal maps it is sufficient to use the following simplified version of the bitangent which is generated at pixel/vertex level.
        # fSign = bIsOrientationPreserving ? 1.0f : (-1.0f);
        # bitangent = fSign * cross(vN, tangent);
        # Note that the results are returned unindexed. It is possible to generate a new index list
        # But averaging/overwriting tangent spaces by using an already existing index list WILL produce INCRORRECT results.
        # DO NOT! use an already existing index list.
        void (*m_setTSpace)(const SMikkTSpaceContext * pContext, const float fvTangent[], const float fvBiTangent[], const float fMagS, const float fMagT, const tbool bIsOrientationPreserving, const int iFace, const int iVert)

    struct SMikkTSpaceContext:
        # initialized with callback functions
        SMikkTSpaceInterface * m_pInterface
        # pointer to client side mesh data etc. (passed as the first parameter with every interface call)
        void * m_pUserData

    # these are both thread safe!
    tbool genTangSpaceDefault(const SMikkTSpaceContext * pContext)	# Default (recommended) fAngularThreshold is 180 degrees (which means threshold disabled)
    tbool genTangSpace(const SMikkTSpaceContext * pContext, const float fAngularThreshold)


cdef int getNumFaces(const SMikkTSpaceContext * pContext):
    context = <object>pContext.m_pUserData
    return len(context.indices) // 3


cdef int getNumVerticesOfFace(const SMikkTSpaceContext * pContext, const int iFace):
    '''
    triangle only
    '''
    return 3


cdef void getPosition(const SMikkTSpaceContext * pContext, float fvPosOut[], const int iFace, const int iVert):
    context = <object>pContext.m_pUserData
    index = context.indices[iFace * 3 + iVert] * 3
    
    fvPosOut[0] = context.position[index]
    fvPosOut[1] = context.position[index+1]
    fvPosOut[2] = context.position[index+2]


cdef void getNormal(const SMikkTSpaceContext * pContext, float fvNormOut[], const int iFace, const int iVert):
    context = <object>pContext.m_pUserData
    index = context.indices[iFace * 3 + iVert] * 3

    fvNormOut[0] = context.normal[index]
    fvNormOut[1] = context.normal[index+1]
    fvNormOut[2] = context.normal[index+2]


cdef void getTexCoord(const SMikkTSpaceContext * pContext, float fvTexcOut[], const int iFace, const int iVert):
    context = <object>pContext.m_pUserData
    index = context.indices[iFace * 3 + iVert] * 2

    fvTexcOut[0] = context.uv[index]
    fvTexcOut[1] = context.uv[index+1]


cdef void setTSpaceBasic(const SMikkTSpaceContext * pContext, const float fvTangent[], const float fSign, const int iFace, const int iVert):
    context = <object>pContext.m_pUserData
    index = context.indices[iFace * 3 + iVert] * 4

    context.tangent[index] = fvTangent[0]
    context.tangent[index+1] = fvTangent[1]
    context.tangent[index+2] = fvTangent[2]
    context.tangent[index+3] = fSign


cdef class Context:
    cdef SMikkTSpaceInterface m_interface
    cdef SMikkTSpaceContext m_context
    cdef public object indices
    cdef public float[::1] position
    cdef public float[::1] normal
    cdef public float[::1] uv
    cdef public float[::1] tangent

    def __cinit__(self, indices, float[::1]position, float[::1]normal, float[::1]uv, float[::1]tangent):
        self.indices = indices
        self.position = position
        self.normal = normal
        self.uv = uv
        self.tangent = tangent

        self.m_interface.m_getNumFaces = &getNumFaces
        self.m_interface.m_getNumVerticesOfFace = &getNumVerticesOfFace
        self.m_interface.m_getPosition = &getPosition
        self.m_interface.m_getNormal = &getNormal
        self.m_interface.m_getTexCoord = &getTexCoord
        self.m_interface.m_setTSpaceBasic = &setTSpaceBasic

        self.m_context.m_pInterface = &self.m_interface
        self.m_context.m_pUserData = <void *>self

    cpdef gen_default(self):
        return genTangSpaceDefault(&self.m_context)

#    cpdef gen(self, float fAngularThreshold):
#        return genTangSpace(&self.m_context, fAngularThreshold)


def gen_default(indices, const float[::1]position, const float[::1]normal, const float[::1]uv):
    import array
    position_count = len(position) // 3
    tangent = array.array('f', [0.0] * (4 * position_count))
    c = Context(indices, position, normal, uv, tangent)
    if c.gen_default():
        return tangent
