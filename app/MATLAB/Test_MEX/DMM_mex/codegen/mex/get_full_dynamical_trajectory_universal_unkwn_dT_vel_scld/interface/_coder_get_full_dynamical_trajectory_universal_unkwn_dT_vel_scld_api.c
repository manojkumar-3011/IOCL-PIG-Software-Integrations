/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_api.c
 *
 * Code generation for function
 * '_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_api'
 *
 */

/* Include files */
#include "_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_api.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_data.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_emxutil.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_types.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static emlrtRTEInfo
    o_emlrtRTEI =
        {
            1, /* lineNo */
            1, /* colNo */
            "_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_"
            "api", /* fName */
            ""     /* pName */
};

/* Function Declarations */
static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[21];

static void c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, emxArray_real_T *y);

static void d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               emxArray_real_T *y);

static void e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, emxArray_real_T *y);

static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                 const char_T *identifier))[21];

static const mxArray *emlrt_marshallOut(const emxArray_real_T *u);

static void f_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               emxArray_real_T *y);

static real_T g_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                 const char_T *identifier);

static real_T h_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                 const emlrtMsgIdentifier *parentId);

static real_T (*i_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier))[3];

static real_T (*j_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[3];

static real_T (*k_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier))[4];

static real_T (*l_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[4];

static real_T (*m_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId))[21];

static void n_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                               const emlrtMsgIdentifier *msgId,
                               emxArray_real_T *ret);

static void o_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                               const emlrtMsgIdentifier *msgId,
                               emxArray_real_T *ret);

static real_T p_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                 const emlrtMsgIdentifier *msgId);

static real_T (*q_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId))[3];

static real_T (*r_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId))[4];

/* Function Definitions */
static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[21]
{
  real_T(*y)[21];
  y = m_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static void c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, emxArray_real_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  d_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

static void d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               emxArray_real_T *y)
{
  n_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

static void e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, emxArray_real_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  f_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                 const char_T *identifier))[21]
{
  emlrtMsgIdentifier thisId;
  real_T(*y)[21];
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = b_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId);
  emlrtDestroyArray(&nullptr);
  return y;
}

static const mxArray *emlrt_marshallOut(const emxArray_real_T *u)
{
  static const int32_T iv[2] = {0, 0};
  const mxArray *m;
  const mxArray *y;
  const real_T *u_data;
  u_data = u->data;
  y = NULL;
  m = emlrtCreateNumericArray(2, (const void *)&iv[0], mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m, (void *)&u_data[0]);
  emlrtSetDimensions((mxArray *)m, &u->size[0], 2);
  emlrtAssign(&y, m);
  return y;
}

static void f_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               emxArray_real_T *y)
{
  o_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

static real_T g_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                 const char_T *identifier)
{
  emlrtMsgIdentifier thisId;
  real_T y;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = h_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId);
  emlrtDestroyArray(&nullptr);
  return y;
}

static real_T h_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                 const emlrtMsgIdentifier *parentId)
{
  real_T y;
  y = p_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T (*i_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier))[3]
{
  emlrtMsgIdentifier thisId;
  real_T(*y)[3];
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = j_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId);
  emlrtDestroyArray(&nullptr);
  return y;
}

static real_T (*j_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[3]
{
  real_T(*y)[3];
  y = q_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T (*k_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier))[4]
{
  emlrtMsgIdentifier thisId;
  real_T(*y)[4];
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = l_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId);
  emlrtDestroyArray(&nullptr);
  return y;
}

static real_T (*l_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[4]
{
  real_T(*y)[4];
  y = r_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T (*m_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId))[21]
{
  static const int32_T dims = 21;
  real_T(*ret)[21];
  int32_T i;
  boolean_T b = false;
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                            (const void *)&dims, &b, &i);
  ret = (real_T(*)[21])emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static void n_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                               const emlrtMsgIdentifier *msgId,
                               emxArray_real_T *ret)
{
  static const int32_T dims[2] = {1, -1};
  int32_T iv[2];
  int32_T i;
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret->allocatedSize = iv[0] * iv[1];
  i = ret->size[0] * ret->size[1];
  ret->size[0] = iv[0];
  ret->size[1] = iv[1];
  emxEnsureCapacity_real_T(sp, ret, i, (emlrtRTEInfo *)NULL);
  ret->data = (real_T *)emlrtMxGetData(src);
  ret->canFreeData = false;
  emlrtDestroyArray(&src);
}

static void o_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                               const emlrtMsgIdentifier *msgId,
                               emxArray_real_T *ret)
{
  static const int32_T dims[2] = {3, -1};
  int32_T iv[2];
  int32_T i;
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret->allocatedSize = iv[0] * iv[1];
  i = ret->size[0] * ret->size[1];
  ret->size[0] = iv[0];
  ret->size[1] = iv[1];
  emxEnsureCapacity_real_T(sp, ret, i, (emlrtRTEInfo *)NULL);
  ret->data = (real_T *)emlrtMxGetData(src);
  ret->canFreeData = false;
  emlrtDestroyArray(&src);
}

static real_T p_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                 const emlrtMsgIdentifier *msgId)
{
  static const int32_T dims = 0;
  real_T ret;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 0U,
                          (const void *)&dims);
  ret = *(real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static real_T (*q_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId))[3]
{
  static const int32_T dims[2] = {1, 3};
  real_T(*ret)[3];
  int32_T iv[2];
  boolean_T bv[2] = {false, false};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret = (real_T(*)[3])emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static real_T (*r_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId))[4]
{
  static const int32_T dims = 4;
  real_T(*ret)[4];
  int32_T i;
  boolean_T b = false;
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                            (const void *)&dims, &b, &i);
  ret = (real_T(*)[4])emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

void c_get_full_dynamical_trajectory(const mxArray *const prhs[7], int32_T nlhs,
                                     const mxArray *plhs[7])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  emxArray_real_T *acc_ef;
  emxArray_real_T *g_all;
  emxArray_real_T *indices;
  emxArray_real_T *odo_gen;
  emxArray_real_T *p_gen;
  emxArray_real_T *q;
  emxArray_real_T *q_dot;
  emxArray_real_T *v;
  emxArray_real_T *v_dot;
  emxArray_real_T *w_all;
  real_T(*new_agb_j)[21];
  real_T(*best_initial_orientation)[4];
  real_T(*start_gps)[3];
  real_T downsampling;
  st.tls = emlrtRootTLSGlobal;
  emlrtHeapReferenceStackEnterFcnR2012b(&st);
  /* Marshall function inputs */
  new_agb_j = emlrt_marshallIn(&st, emlrtAlias(prhs[0]), "new_agb_j");
  emxInit_real_T(&st, &indices, &o_emlrtRTEI);
  indices->canFreeData = false;
  c_emlrt_marshallIn(&st, emlrtAlias(prhs[1]), "indices", indices);
  emxInit_real_T(&st, &g_all, &o_emlrtRTEI);
  g_all->canFreeData = false;
  e_emlrt_marshallIn(&st, emlrtAlias(prhs[2]), "g_all", g_all);
  emxInit_real_T(&st, &w_all, &o_emlrtRTEI);
  w_all->canFreeData = false;
  e_emlrt_marshallIn(&st, emlrtAlias(prhs[3]), "w_all", w_all);
  downsampling = g_emlrt_marshallIn(&st, emlrtAliasP(prhs[4]), "downsampling");
  start_gps = i_emlrt_marshallIn(&st, emlrtAlias(prhs[5]), "start_gps");
  best_initial_orientation =
      k_emlrt_marshallIn(&st, emlrtAlias(prhs[6]), "best_initial_orientation");
  /* Invoke the target function */
  emxInit_real_T(&st, &q_dot, &o_emlrtRTEI);
  emxInit_real_T(&st, &q, &o_emlrtRTEI);
  emxInit_real_T(&st, &v_dot, &o_emlrtRTEI);
  emxInit_real_T(&st, &v, &o_emlrtRTEI);
  emxInit_real_T(&st, &p_gen, &o_emlrtRTEI);
  emxInit_real_T(&st, &odo_gen, &o_emlrtRTEI);
  emxInit_real_T(&st, &acc_ef, &o_emlrtRTEI);
  get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(
      &st, *new_agb_j, indices, g_all, w_all, downsampling, *start_gps,
      *best_initial_orientation, q_dot, q, v_dot, v, p_gen, odo_gen, acc_ef);
  emxFree_real_T(&st, &w_all);
  emxFree_real_T(&st, &g_all);
  emxFree_real_T(&st, &indices);
  /* Marshall function outputs */
  q_dot->canFreeData = false;
  plhs[0] = emlrt_marshallOut(q_dot);
  emxFree_real_T(&st, &q_dot);
  if (nlhs > 1) {
    q->canFreeData = false;
    plhs[1] = emlrt_marshallOut(q);
  }
  emxFree_real_T(&st, &q);
  if (nlhs > 2) {
    v_dot->canFreeData = false;
    plhs[2] = emlrt_marshallOut(v_dot);
  }
  emxFree_real_T(&st, &v_dot);
  if (nlhs > 3) {
    v->canFreeData = false;
    plhs[3] = emlrt_marshallOut(v);
  }
  emxFree_real_T(&st, &v);
  if (nlhs > 4) {
    p_gen->canFreeData = false;
    plhs[4] = emlrt_marshallOut(p_gen);
  }
  emxFree_real_T(&st, &p_gen);
  if (nlhs > 5) {
    odo_gen->canFreeData = false;
    plhs[5] = emlrt_marshallOut(odo_gen);
  }
  emxFree_real_T(&st, &odo_gen);
  if (nlhs > 6) {
    acc_ef->canFreeData = false;
    plhs[6] = emlrt_marshallOut(acc_ef);
  }
  emxFree_real_T(&st, &acc_ef);
  emlrtHeapReferenceStackLeaveFcnR2012b(&st);
}

/* End of code generation
 * (_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_api.c) */
