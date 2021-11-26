cdef extern from "MikkTSpace/mikktspace.h":
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


cdef class Context:
    cdef SMikkTSpaceContext *m_context

    cpdef gen_default(self):
        return genTangSpaceDefault(self.m_context)

    cpdef gen(self, float fAngularThreshold):
        return genTangSpaceDefault(self.m_context)