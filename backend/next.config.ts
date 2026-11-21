import type { NextConfig } from "next";

// LOCAL DEV ONLY: lets the Flutter *web* build (Chrome) call the API from another port.
// The mobile apps never need CORS. Leave ALLOW_DEV_CORS unset in production.
const devCors = process.env.ALLOW_DEV_CORS === "true";

const nextConfig: NextConfig = {
  /* config options here */
  cacheComponents: true,
  partialPrefetching: true,
  async headers() {
    if (!devCors) return [];
    return [
      {
        source: "/api/:path*",
        headers: [
          { key: "Access-Control-Allow-Origin", value: "*" },
          { key: "Access-Control-Allow-Methods", value: "GET,POST,PUT,PATCH,DELETE,OPTIONS" },
          { key: "Access-Control-Allow-Headers", value: "authorization,content-type,idempotency-key" },
        ],
      },
    ];
  },
};

export default nextConfig;
