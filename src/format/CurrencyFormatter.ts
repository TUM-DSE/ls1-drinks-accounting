export default class CurrencyFormatter {
  static format(value: number) {
    const formatter = new Intl.NumberFormat("de-DE", {
      style: "currency",
      currency: "EUR",
    });
    return formatter.format(value);
  }
}
