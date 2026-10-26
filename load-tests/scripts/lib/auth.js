import http from 'k6/http';
import { check } from 'k6';
import { targets, testUsers, userIdForVu, userEmail } from './config.js';

// Tokens are cached per-VU in module scope. k6 keeps each VU's globals isolated,
// so this is effectively a per-VU cache without a shared map.
let cachedToken = null;
let cachedUserId = null;

// Login flow: request OTP, submit the magic OTP (MAGIC_OTP enabled in non-prod; in prod
// this requires a pre-provisioned test-tenant where TWILIO is stubbed or the user has a
// known OTP. See README "Targeting prod" section.)
export function getAuthHeader() {
  if (cachedToken) {
    return { Authorization: `Bearer ${cachedToken}` };
  }

  const vu = __VU || 1;
  cachedUserId = userIdForVu(vu);
  const email = userEmail(cachedUserId);

  const otpRes = http.post(
    `${targets.backend}/auth/otp/request`,
    JSON.stringify({ email }),
    { headers: { 'Content-Type': 'application/json' }, tags: { name: 'auth_otp_request' } },
  );

  check(otpRes, { 'otp request 2xx': (r) => r.status >= 200 && r.status < 300 });

  const verifyRes = http.post(
    `${targets.backend}/auth/otp/verify`,
    JSON.stringify({ email, otp: testUsers.magicOtp }),
    { headers: { 'Content-Type': 'application/json' }, tags: { name: 'auth_otp_verify' } },
  );

  check(verifyRes, { 'otp verify 2xx': (r) => r.status >= 200 && r.status < 300 });

  if (verifyRes.status >= 200 && verifyRes.status < 300) {
    const body = verifyRes.json();
    cachedToken = body && (body.accessToken || body.token);
  }

  return cachedToken ? { Authorization: `Bearer ${cachedToken}` } : {};
}

export function currentUserId() {
  return cachedUserId;
}
