class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://5on0mm6m5d.execute-api.ap-south-1.amazonaws.com',
  );

  /// CloudFront in front of s3://vidarka-tx-output (see api/functions_serverless.yaml).
  static const assetsBaseUrl = String.fromEnvironment(
    'ASSETS_BASE_URL',
    defaultValue: 'https://d30vbcyuzdv53d.cloudfront.net',
  );

  /// When true, future-time slots on Today are grayed out / locked until their
  /// start time. Keep false for TEST builds so every tile stays active/clickable.
  /// Set true for production time-gating.
  static const bool lockFutureSlotsByTime = false;
}
