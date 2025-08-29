/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld.c
 *
 * Code generation for function
 * 'get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld'
 *
 */

/* Include files */
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld.h"
#include "expm.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_data.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_emxutil.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_types.h"
#include "quat2rotm.h"
#include "rt_nonfinite.h"
#include "mwmathutil.h"
#include <emmintrin.h>
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = {
    39,                                                          /* lineNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fcnName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pathName */
};

static emlrtRSInfo b_emlrtRSI = {
    48,                                                          /* lineNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fcnName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pathName */
};

static emlrtRSInfo c_emlrtRSI = {
    58,                                                          /* lineNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fcnName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pathName */
};

static emlrtRSInfo k_emlrtRSI = {
    18,                       /* lineNo */
    "pig_odo_eucld_dynamics", /* fcnName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/pig_odo_eucld_dynamics.m" /* pathName */
};

static emlrtRSInfo l_emlrtRSI = {
    32,                       /* lineNo */
    "pig_odo_eucld_dynamics", /* fcnName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/pig_odo_eucld_dynamics.m" /* pathName */
};

static emlrtBCInfo emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    24,                                                          /* lineNo */
    33,                                                          /* colNo */
    "indices",                                                   /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo b_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    24,                                                          /* lineNo */
    44,                                                          /* colNo */
    "indices",                                                   /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo c_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    35,                                                          /* lineNo */
    9,                                                           /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo d_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    41,                                                          /* lineNo */
    21,                                                          /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo e_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    37,                                                          /* lineNo */
    13,                                                          /* colNo */
    "p_gen",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo f_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    46,                                                          /* lineNo */
    38,                                                          /* colNo */
    "p_gen",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo g_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    36,                                                          /* lineNo */
    9,                                                           /* colNo */
    "v",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo h_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    46,                                                          /* lineNo */
    54,                                                          /* colNo */
    "v",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo i_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    47,                                                          /* lineNo */
    22,                                                          /* colNo */
    "g_all",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo j_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    47,                                                          /* lineNo */
    36,                                                          /* colNo */
    "w_all",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo k_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    49,                                                          /* lineNo */
    39,                                                          /* colNo */
    "p_gen",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo l_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    49,                                                          /* lineNo */
    57,                                                          /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo m_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    49,                                                          /* lineNo */
    75,                                                          /* colNo */
    "v",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo n_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    51,                                                          /* lineNo */
    28,                                                          /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo o_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    51,                                                          /* lineNo */
    38,                                                          /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo p_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    52,                                                          /* lineNo */
    28,                                                          /* colNo */
    "v",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo q_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    52,                                                          /* lineNo */
    38,                                                          /* colNo */
    "v",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo r_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    53,                                                          /* lineNo */
    44,                                                          /* colNo */
    "p_gen",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo s_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    53,                                                          /* lineNo */
    61,                                                          /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo t_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    58,                                                          /* lineNo */
    38,                                                          /* colNo */
    "q",                                                         /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo u_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    51,                                                          /* lineNo */
    17,                                                          /* colNo */
    "q_dot",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo v_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    52,                                                          /* lineNo */
    17,                                                          /* colNo */
    "v_dot",                                                     /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo w_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    39,                                                          /* lineNo */
    14,                                                          /* colNo */
    "acc_ef",                                                    /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo x_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    58,                                                          /* lineNo */
    18,                                                          /* colNo */
    "acc_ef",                                                    /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo y_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    46,                                                          /* lineNo */
    14,                                                          /* colNo */
    "odo_gen",                                                   /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtBCInfo ab_emlrtBCI = {
    -1,                                                          /* iFirst */
    -1,                                                          /* iLast */
    49,                                                          /* lineNo */
    19,                                                          /* colNo */
    "odo_gen",                                                   /* aName */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m", /* pName */
    0           /* checkKind */
};

static emlrtRTEInfo h_emlrtRTEI = {
    28,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

static emlrtRTEInfo i_emlrtRTEI = {
    29,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

static emlrtRTEInfo j_emlrtRTEI = {
    30,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

static emlrtRTEInfo k_emlrtRTEI = {
    31,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

static emlrtRTEInfo l_emlrtRTEI = {
    32,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

static emlrtRTEInfo m_emlrtRTEI = {
    33,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

static emlrtRTEInfo n_emlrtRTEI = {
    34,                                                          /* lineNo */
    5,                                                           /* colNo */
    "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld", /* fName */
    "/home/sidgirase/Documents/Project/FSP_ver0r4_sg_fork_toIOCL/Test_MEX/"
    "DMM_mex/get_full_dynamical_trajectory_universal_unkwn_dT_ve"
    "l_scld.m" /* pName */
};

/* Function Definitions */
void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(
    const emlrtStack *sp, const real_T new_agb_j[21],
    const emxArray_real_T *indices, const emxArray_real_T *g_all,
    const emxArray_real_T *w_all, real_T downsampling,
    const real_T start_gps[3], const real_T best_initial_orientation[4],
    emxArray_real_T *q_dot, emxArray_real_T *q, emxArray_real_T *v_dot,
    emxArray_real_T *v, emxArray_real_T *p_gen, emxArray_real_T *odo_gen,
    emxArray_real_T *acc_ef)
{
  static const int8_T iv[6] = {1, 2, 3, 7, 8, 9};
  __m128d r;
  __m128d r1;
  emlrtStack b_st;
  emlrtStack st;
  real_T dv2[17];
  real_T x[17];
  real_T a[16];
  real_T dv[16];
  real_T dv1[16];
  real_T C_nb[9];
  real_T params[8];
  real_T u[6];
  real_T q0[4];
  real_T v_odo_inertial[3];
  real_T w_b[3];
  const real_T *g_all_data;
  const real_T *indices_data;
  const real_T *w_all_data;
  real_T dT;
  real_T *acc_ef_data;
  real_T *odo_gen_data;
  real_T *p_gen_data;
  real_T *q_data;
  real_T *q_dot_data;
  real_T *v_data;
  real_T *v_dot_data;
  int32_T i;
  int32_T ix;
  int32_T loop_ub;
  int32_T loop_ub_tmp;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  w_all_data = w_all->data;
  g_all_data = g_all->data;
  indices_data = indices->data;
  /*      east_radius_of_earth = 6378100; % equatorial (Wikipedia)  */
  /*      north_radius_of_earth = 6356800; % polar (Wikipedia)  */
  /*      manifld_factr_en = 1; % manifold is default  */
  /*      rotn_factr_en = 1; % earth rotation is default value  */
  /*  radians per second [=7.292115e-5*180/pi*86400 = 360.9856]  */
  /*   */
  /*  acc_gain_mat = diag(agb_now(2:4));  */
  /*  gyro_gain_mat = diag(agb_now(8:10));  */
  for (i = 0; i < 6; i++) {
    params[i] = new_agb_j[iv[i]];
  }
  params[6] = new_agb_j[20] * downsampling / 10.0;
  params[7] = new_agb_j[0];
  _mm_storeu_pd(&q0[0], _mm_add_pd(_mm_loadu_pd(&best_initial_orientation[0]),
                                   _mm_loadu_pd(&new_agb_j[13])));
  _mm_storeu_pd(&q0[2], _mm_add_pd(_mm_loadu_pd(&best_initial_orientation[2]),
                                   _mm_loadu_pd(&new_agb_j[15])));
  /*  q0 =
   * rotm2quat(rotx(start_gps(2))*roty(start_gps(1))*quat2rotm(best_initial_orientation'))'...
   */
  /*       + new_agb_j(14:17);  */
  loop_ub = indices->size[1];
  if (indices->size[1] < 2) {
    emlrtDynamicBoundsCheckR2012b(2, 1, indices->size[1], &emlrtBCI,
                                  (emlrtConstCTX)sp);
  }
  if (indices->size[1] < 1) {
    emlrtDynamicBoundsCheckR2012b(1, 1, indices->size[1], &b_emlrtBCI,
                                  (emlrtConstCTX)sp);
  }
  dT =
      new_agb_j[20] * (indices_data[1] - indices_data[0]) * downsampling / 10.0;
  /*   */
  i = q_dot->size[0] * q_dot->size[1];
  q_dot->size[0] = 4;
  q_dot->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, q_dot, i, &h_emlrtRTEI);
  q_dot_data = q_dot->data;
  loop_ub_tmp = indices->size[1] << 2;
  for (i = 0; i < loop_ub_tmp; i++) {
    q_dot_data[i] = 0.0;
  }
  i = q->size[0] * q->size[1];
  q->size[0] = 4;
  q->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, q, i, &i_emlrtRTEI);
  q_data = q->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    q_data[i] = 0.0;
  }
  i = v_dot->size[0] * v_dot->size[1];
  v_dot->size[0] = 3;
  v_dot->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, v_dot, i, &j_emlrtRTEI);
  v_dot_data = v_dot->data;
  loop_ub_tmp = 3 * indices->size[1];
  for (i = 0; i < loop_ub_tmp; i++) {
    v_dot_data[i] = 0.0;
  }
  i = v->size[0] * v->size[1];
  v->size[0] = 3;
  v->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, v, i, &k_emlrtRTEI);
  v_data = v->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    v_data[i] = 0.0;
  }
  i = p_gen->size[0] * p_gen->size[1];
  p_gen->size[0] = 3;
  p_gen->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, p_gen, i, &l_emlrtRTEI);
  p_gen_data = p_gen->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    p_gen_data[i] = 0.0;
  }
  i = odo_gen->size[0] * odo_gen->size[1];
  odo_gen->size[0] = 1;
  odo_gen->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, odo_gen, i, &m_emlrtRTEI);
  odo_gen_data = odo_gen->data;
  for (i = 0; i < loop_ub; i++) {
    odo_gen_data[i] = 0.0;
  }
  i = acc_ef->size[0] * acc_ef->size[1];
  acc_ef->size[0] = 3;
  acc_ef->size[1] = indices->size[1];
  emxEnsureCapacity_real_T(sp, acc_ef, i, &n_emlrtRTEI);
  acc_ef_data = acc_ef->data;
  for (i = 0; i < loop_ub_tmp; i++) {
    acc_ef_data[i] = 0.0;
  }
  if (indices->size[1] < 1) {
    emlrtDynamicBoundsCheckR2012b(1, 1, indices->size[1], &c_emlrtBCI,
                                  (emlrtConstCTX)sp);
  }
  q_data[0] = q0[0];
  q_data[1] = q0[1];
  q_data[2] = q0[2];
  q_data[3] = q0[3];
  /*  <-- normalized later  */
  if (indices->size[1] < 1) {
    emlrtDynamicBoundsCheckR2012b(1, 1, indices->size[1], &g_emlrtBCI,
                                  (emlrtConstCTX)sp);
  }
  v_data[0] = new_agb_j[17];
  v_data[1] = new_agb_j[18];
  v_data[2] = new_agb_j[19];
  /*   */
  if (indices->size[1] < 1) {
    emlrtDynamicBoundsCheckR2012b(1, 1, indices->size[1], &e_emlrtBCI,
                                  (emlrtConstCTX)sp);
  }
  p_gen_data[0] = start_gps[0];
  p_gen_data[1] = start_gps[1];
  p_gen_data[2] = start_gps[2];
  /*   */
  if (indices->size[1] < 1) {
    emlrtDynamicBoundsCheckR2012b(1, 1, indices->size[1], &w_emlrtBCI,
                                  (emlrtConstCTX)sp);
  }
  st.site = &emlrtRSI;
  quat2rotm(&st, q0, C_nb);
  for (i = 0; i < 3; i++) {
    acc_ef_data[i] = (C_nb[i] * 0.0 + C_nb[i + 3] * 0.0) + C_nb[i + 6] * 9.81;
  }
  if (indices->size[1] - 2 >= 0) {
    dv[0] = 0.0 * params[6];
    dv[5] = 0.0 * params[6];
    dv[10] = 0.0 * params[6];
    dv[15] = 0.0 * params[6];
  }
  if (loop_ub - 2 >= 0) {
    r = _mm_loadu_pd(&params[3]);
    r1 = _mm_set1_pd(dT);
  }
  for (ix = 0; ix <= loop_ub - 2; ix++) {
    __m128d r2;
    __m128d r3;
    real_T absxk;
    real_T b_x;
    real_T d;
    real_T scale;
    real_T t;
    real_T v_odo_current;
    real_T y;
    int32_T absxk_tmp;
    int32_T x_tmp;
    if (ix + 1 > q->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, q->size[1], &d_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    scale = 3.3121686421112381E-170;
    absxk = muDoubleScalarAbs(q_data[4 * ix]);
    if (absxk > 3.3121686421112381E-170) {
      y = 1.0;
      scale = absxk;
    } else {
      t = absxk / 3.3121686421112381E-170;
      y = t * t;
    }
    absxk = muDoubleScalarAbs(q_data[4 * ix + 1]);
    if (absxk > scale) {
      t = scale / absxk;
      y = y * t * t + 1.0;
      scale = absxk;
    } else {
      t = absxk / scale;
      y += t * t;
    }
    absxk_tmp = 4 * ix + 2;
    absxk = muDoubleScalarAbs(q_data[absxk_tmp]);
    if (absxk > scale) {
      t = scale / absxk;
      y = y * t * t + 1.0;
      scale = absxk;
    } else {
      t = absxk / scale;
      y += t * t;
    }
    absxk = muDoubleScalarAbs(q_data[4 * ix + 3]);
    if (absxk > scale) {
      t = scale / absxk;
      y = y * t * t + 1.0;
      scale = absxk;
    } else {
      t = absxk / scale;
      y += t * t;
    }
    y = scale * muDoubleScalarSqrt(y);
    /*  dT =
     * obj.downsampling*(indices(ix)-indices(ix-1))/obj.sampling_frequency;  */
    /*   */
    if (ix + 1 > p_gen->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, p_gen->size[1], &f_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 1 > v->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, v->size[1], &h_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 1 > odo_gen->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, odo_gen->size[1], &y_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    x[0] = odo_gen_data[ix];
    x[1] = p_gen_data[3 * ix];
    loop_ub_tmp = 3 * ix + 1;
    x[2] = p_gen_data[loop_ub_tmp];
    x_tmp = 3 * ix + 2;
    x[3] = p_gen_data[x_tmp];
    r2 = _mm_loadu_pd(&q_data[4 * ix]);
    r3 = _mm_set1_pd(y);
    _mm_storeu_pd(&x[4], _mm_div_pd(r2, r3));
    r2 = _mm_loadu_pd(&q_data[absxk_tmp]);
    _mm_storeu_pd(&x[6], _mm_div_pd(r2, r3));
    x[8] = v_data[3 * ix];
    x[11] = new_agb_j[4];
    x[14] = new_agb_j[10];
    x[9] = v_data[loop_ub_tmp];
    x[12] = new_agb_j[5];
    x[15] = new_agb_j[11];
    x[10] = v_data[x_tmp];
    x[13] = new_agb_j[6];
    x[16] = new_agb_j[12];
    if (ix + 1 > g_all->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, g_all->size[1], &i_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 1 > w_all->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, w_all->size[1], &j_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    u[0] = g_all_data[3 * ix];
    u[3] = w_all_data[3 * ix];
    u[1] = g_all_data[loop_ub_tmp];
    u[4] = w_all_data[loop_ub_tmp];
    u[2] = g_all_data[x_tmp];
    u[5] = w_all_data[x_tmp];
    st.site = &b_emlrtRSI;
    /*  equatorial (Wikipedia)  */
    /*  polar (Wikipedia)  */
    /*  manifold is default  */
    /*  earth rotation is default value  */
    /*  radians per second [=7.292115e-5*180/pi*86400 = 360.9856]  */
    /*  o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17)
     * [+] imu_a <--u(1:3) | imu_w <--u(4:6)   */
    b_st.site = &k_emlrtRSI;
    quat2rotm(&b_st, &x[4], C_nb);
    /*  C_nb =
     * [-0.999487613146384,0.029287284528011,-0.011579364117620;-0.029993627022430,-0.771198451711062,0.635845821441784;0.009692736486792,0.635867574759681,0.771681529525928];
     */
    /*  disp(quat2rotm(q_gen')-C_nb) */
    v_odo_current = u[2] * params[7];
    r2 = _mm_loadu_pd(&C_nb[0]);
    r2 = _mm_mul_pd(r2, _mm_set1_pd(v_odo_current));
    r3 = _mm_loadu_pd(&C_nb[3]);
    r3 = _mm_mul_pd(r3, _mm_set1_pd(0.0));
    r2 = _mm_add_pd(r2, r3);
    r3 = _mm_loadu_pd(&C_nb[6]);
    r3 = _mm_mul_pd(r3, _mm_set1_pd(0.0));
    r2 = _mm_add_pd(r2, r3);
    _mm_storeu_pd(&v_odo_inertial[0], r2);
    v_odo_inertial[2] =
        (C_nb[2] * v_odo_current + C_nb[5] * 0.0) + C_nb[8] * 0.0;
    /*   */
    if (muDoubleScalarIsInf(x[1]) || muDoubleScalarIsNaN(x[1])) {
      b_x = rtNaN;
    } else {
      int8_T n;
      b_x = muDoubleScalarRem(x[1], 360.0);
      scale = muDoubleScalarAbs(b_x);
      if (scale > 180.0) {
        if (b_x > 0.0) {
          b_x -= 360.0;
        } else {
          b_x += 360.0;
        }
        scale = muDoubleScalarAbs(b_x);
      }
      if (scale <= 45.0) {
        b_x *= 0.017453292519943295;
        n = 0;
      } else if (scale <= 135.0) {
        if (b_x > 0.0) {
          b_x = 0.017453292519943295 * (b_x - 90.0);
          n = 1;
        } else {
          b_x = 0.017453292519943295 * (b_x + 90.0);
          n = -1;
        }
      } else if (b_x > 0.0) {
        b_x = 0.017453292519943295 * (b_x - 180.0);
        n = 2;
      } else {
        b_x = 0.017453292519943295 * (b_x + 180.0);
        n = -2;
      }
      if (n == 0) {
        b_x = muDoubleScalarCos(b_x);
      } else if (n == 1) {
        b_x = -muDoubleScalarSin(b_x);
      } else if (n == -1) {
        b_x = muDoubleScalarSin(b_x);
      } else {
        b_x = -muDoubleScalarCos(b_x);
      }
    }
    r2 = _mm_loadu_pd(&u[3]);
    r3 = _mm_loadu_pd(&x[14]);
    _mm_storeu_pd(&w_b[0], _mm_add_pd(_mm_mul_pd(r, r2), r3));
    w_b[2] = params[5] * u[5] + new_agb_j[12];
    scale = 0.5 * -w_b[0] * params[6];
    dv[4] = scale;
    absxk = 0.5 * -w_b[1] * params[6];
    dv[8] = absxk;
    t = 0.5 * -w_b[2] * params[6];
    dv[12] = t;
    y = 0.5 * w_b[0] * params[6];
    dv[1] = y;
    d = 0.5 * w_b[2] * params[6];
    dv[9] = d;
    dv[13] = absxk;
    absxk = 0.5 * w_b[1] * params[6];
    dv[2] = absxk;
    dv[6] = t;
    dv[14] = y;
    dv[3] = d;
    dv[7] = absxk;
    dv[11] = scale;
    memcpy(&dv1[0], &dv[0], 16U * sizeof(real_T));
    b_st.site = &l_emlrtRSI;
    expm(&b_st, dv1, a);
    /*  [not needed] /norm(q_gen(q,bs,imu_w));  */
    scale = x[4];
    absxk = x[5];
    t = x[6];
    y = x[7];
    for (i = 0; i <= 2; i += 2) {
      r2 = _mm_loadu_pd(&a[i]);
      r2 = _mm_mul_pd(r2, _mm_set1_pd(scale));
      r3 = _mm_loadu_pd(&a[i + 4]);
      r3 = _mm_mul_pd(r3, _mm_set1_pd(absxk));
      r2 = _mm_add_pd(r2, r3);
      r3 = _mm_loadu_pd(&a[i + 8]);
      r3 = _mm_mul_pd(r3, _mm_set1_pd(t));
      r2 = _mm_add_pd(r2, r3);
      r3 = _mm_loadu_pd(&a[i + 12]);
      r3 = _mm_mul_pd(r3, _mm_set1_pd(y));
      r2 = _mm_add_pd(r2, r3);
      _mm_storeu_pd(&q0[i], r2);
    }
    memset(&dv2[0], 0, 11U * sizeof(real_T));
    x[0] += params[6] * v_odo_current;
    x[1] += params[6] * (180.0 * v_odo_inertial[0] /
                         (3.1415926535897931 * (x[3] + 6.3568E+6)));
    x[2] += params[6] * (-180.0 * v_odo_inertial[1] /
                         (3.1415926535897931 * (x[3] + 6.3781E+6) * b_x));
    x[3] += v_odo_inertial[2] * params[6];
    x[4] = q0[0];
    x[5] = q0[1];
    x[6] = q0[2];
    x[7] = q0[3];
    x[8] = v_odo_inertial[0];
    x[9] = v_odo_inertial[1];
    x[10] = v_odo_inertial[2];
    for (i = 0; i < 6; i++) {
      dv2[i + 11] = x[i + 11];
      x[i + 11] = 0.0;
    }
    for (i = 0; i <= 14; i += 2) {
      r2 = _mm_loadu_pd(&dv2[i]);
      r3 = _mm_loadu_pd(&x[i]);
      _mm_storeu_pd(&x[i], _mm_add_pd(r2, r3));
    }
    if (ix + 2 > odo_gen->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, odo_gen->size[1], &ab_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    odo_gen_data[ix + 1] = x[0];
    if (ix + 2 > p_gen->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, p_gen->size[1], &k_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    i = 3 * (ix + 1);
    p_gen_data[i] = x[1];
    p_gen_data[i + 1] = x[2];
    p_gen_data[i + 2] = x[3];
    if (ix + 2 > q->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, q->size[1], &l_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    loop_ub_tmp = 4 * (ix + 1);
    q_data[loop_ub_tmp] = x[4];
    q_data[loop_ub_tmp + 1] = x[5];
    q_data[loop_ub_tmp + 2] = x[6];
    q_data[loop_ub_tmp + 3] = x[7];
    if (ix + 2 > v->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, v->size[1], &m_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    v_data[i] = x[8];
    v_data[i + 1] = x[9];
    v_data[i + 2] = x[10];
    /*   */
    if (ix + 2 > q->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, q->size[1], &n_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 1 > q->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, q->size[1], &o_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 2 > q_dot->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, q_dot->size[1], &u_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    r2 = _mm_loadu_pd(&q_data[loop_ub_tmp]);
    r3 = _mm_loadu_pd(&q_data[4 * ix]);
    _mm_storeu_pd(&q_dot_data[loop_ub_tmp], _mm_div_pd(_mm_sub_pd(r2, r3), r1));
    r2 = _mm_loadu_pd(&q_data[loop_ub_tmp + 2]);
    r3 = _mm_loadu_pd(&q_data[absxk_tmp]);
    _mm_storeu_pd(&q_dot_data[loop_ub_tmp + 2],
                  _mm_div_pd(_mm_sub_pd(r2, r3), r1));
    if (ix + 2 > v->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, v->size[1], &p_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 1 > v->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 1, 1, v->size[1], &q_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 2 > v_dot->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, v_dot->size[1], &v_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    r2 = _mm_loadu_pd(&v_data[i]);
    r3 = _mm_loadu_pd(&v_data[3 * ix]);
    _mm_storeu_pd(&v_dot_data[i], _mm_div_pd(_mm_sub_pd(r2, r3), r1));
    v_dot_data[i + 2] = (v_data[i + 2] - v_data[x_tmp]) / dT;
    if (ix + 2 > p_gen->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, p_gen->size[1], &r_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    if (ix + 2 > q->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, q->size[1], &s_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    /* v_now = v(:,ix);  */
    /*  C_nb = roty(-p_now(1))*rotx(-p_now(2))... */
    /*      *rotx(-t_now*rot_rate_of_earth*180/pi)*quat2rotm(q_now'); %
     * eul2rotm(flip(omega_ie(p)')*t) */
    /*  acc_ef(:,ix) = transpose(C_nb)... */
    /*      *[0;0;earth_gravity];  */
    if (ix + 2 > q->size[1]) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, q->size[1], &t_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    st.site = &c_emlrtRSI;
    quat2rotm(&st, &q_data[4 * (ix + 1)], C_nb);
    if (ix + 2 > loop_ub) {
      emlrtDynamicBoundsCheckR2012b(ix + 2, 1, loop_ub, &x_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    for (loop_ub_tmp = 0; loop_ub_tmp < 3; loop_ub_tmp++) {
      acc_ef_data[loop_ub_tmp + i] =
          (C_nb[3 * loop_ub_tmp] * 0.0 + C_nb[3 * loop_ub_tmp + 1] * 0.0) +
          C_nb[3 * loop_ub_tmp + 2] * 9.81;
    }
    if (*emlrtBreakCheckR2012bFlagVar != 0) {
      emlrtBreakCheckR2012b((emlrtConstCTX)sp);
    }
  }
  /*  odo_gen = odo_gain*dT*cumsum(sqrt(sum(v.*v,1)));  */
}

/* End of code generation
 * (get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld.c) */
