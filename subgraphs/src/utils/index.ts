export function getCurrentPeriodTimestamp(period: String): i32 {
  const now: Date = new Date(Date.now());
  const elapsedMinutesInSecs: number = now.getUTCMinutes() * 60;
  const elapsedSeconds: number = now.getUTCSeconds();
  const hourTimestamp: number =
    Math.floor(f64(now.getTime() / 1000)) - (elapsedMinutesInSecs + elapsedSeconds);

  if (period === "H1") {
    const hourTimestampInMillisecs: number = hourTimestamp * 1000;
    return i32(hourTimestampInMillisecs);
  } else if (period === "H4") {
    const elapsed4HoursInSecs: number = (now.getUTCHours() % 4) * 60 * 60;
    const hour4Timestamp: number =
      Math.floor(f64(now.getTime() / 1000)) -
      elapsed4HoursInSecs -
      (elapsedMinutesInSecs + elapsedSeconds);
    const hour4TimestampInMillisecs: number = hour4Timestamp * 1000;
    return i32(hour4TimestampInMillisecs);
  } else if (period === "D1") {
    const elapsedHoursInSecs: number = now.getUTCHours() * 60 * 60;
    const dayTimestamp: number =
      Math.floor(f64(now.getTime() / 1000)) -
      elapsedHoursInSecs -
      (elapsedMinutesInSecs + elapsedSeconds);
    const dayTimestampInMillisecs: number = dayTimestamp * 1000;
    return i32(dayTimestampInMillisecs);
  }
  return i32(0);
}
