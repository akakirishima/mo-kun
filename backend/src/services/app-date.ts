const DAY_IN_MS = 24 * 60 * 60 * 1000;
const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
const APP_DAY_CUTOFF_HOUR = 3;

export function buildAppDateKey(now: Date): string {
  const shifted = new Date(
    now.getTime() + JST_OFFSET_MS - (APP_DAY_CUTOFF_HOUR * 60 * 60 * 1000),
  );
  const year = shifted.getUTCFullYear();
  const month = `${shifted.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${shifted.getUTCDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function buildAppDateWindow(dateKey: string): { startAt: Date; endAt: Date } {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dateKey);
  if (!match) {
    throw new Error(`invalid_date_key: ${dateKey}`);
  }

  const [, yearText, monthText, dayText] = match;
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  const startAt = new Date(
    Date.UTC(year, month - 1, day, APP_DAY_CUTOFF_HOUR - 9, 0, 0, 0),
  );
  return {
    startAt,
    endAt: new Date(startAt.getTime() + DAY_IN_MS),
  };
}
