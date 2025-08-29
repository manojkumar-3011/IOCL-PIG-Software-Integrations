/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate.c
 *
 * Code generation for function
 * 'get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate'
 *
 */

/* Include files */
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate.h"
#include "_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_data.h"
#include "rt_nonfinite.h"

/* Function Declarations */
static void emlrtExitTimeCleanupDtorFcn(const void *r);

/* Function Definitions */
static void emlrtExitTimeCleanupDtorFcn(const void *r)
{
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_atexit(void)
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtPushHeapReferenceStackR2021a(
      &st, false, NULL, (void *)&emlrtExitTimeCleanupDtorFcn, NULL, NULL, NULL);
  emlrtEnterRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate(void)
{
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation
 * (get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate.c) */
