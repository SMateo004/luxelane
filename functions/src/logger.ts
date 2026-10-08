type LogLevel = 'info' | 'warn' | 'error';

interface LogEntry {
  /** Read by Cloud Logging, so alerts can filter on severity>=ERROR. */
  severity: 'INFO' | 'WARNING' | 'ERROR';
  level: LogLevel;
  fn: string;
  message: string;
  data?: unknown;
  timestamp: string;
}

function log(level: LogLevel, fn: string, message: string, data?: unknown): void {
  const entry: LogEntry = {
    severity: level === 'error' ? 'ERROR' : level === 'warn' ? 'WARNING' : 'INFO',
    level,
    fn,
    message,
    timestamp: new Date().toISOString(),
    ...(data !== undefined && { data }),
  };
  if (level === 'error') {
    console.error(JSON.stringify(entry));
  } else if (level === 'warn') {
    console.warn(JSON.stringify(entry));
  } else {
    console.log(JSON.stringify(entry));
  }
}

export const logger = {
  info: (fn: string, message: string, data?: unknown) => log('info', fn, message, data),
  warn: (fn: string, message: string, data?: unknown) => log('warn', fn, message, data),
  error: (fn: string, message: string, data?: unknown) => log('error', fn, message, data),
};
