/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize.c
 *
 * Code generation for function
 * 'get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize'
 *
 */

/* Include files */
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize.h"
#include "_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_data.h"
#include "rt_nonfinite.h"

/* Function Declarations */
static void
get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_once(void);

/* Function Definitions */
static void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_once(void)
{
  mex_InitInfAndNan();
}

void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize(void)
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2022b(&st);
  emlrtClearAllocCountR2012b(&st, false, 0U, NULL);
  emlrtEnterRtStackR2012b(&st);
  if (emlrtFirstTimeR2012b(emlrtRootTLSGlobal)) {
    get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_once();
  }
}

/* End of code generation
 * (get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize.c) */
