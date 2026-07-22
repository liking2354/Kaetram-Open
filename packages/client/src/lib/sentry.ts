import { init, browserTracingIntegration } from '@sentry/browser';

if (import.meta.env.PROD && globalConfig.sentryDsn)
    init({
        dsn: globalConfig.sentryDsn,
        integrations: [browserTracingIntegration()],
        tracesSampleRate: 1
    });
