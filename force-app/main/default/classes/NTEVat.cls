/** GBP VAT for net catalogue charges and saved inclusive booking amounts. */
public class NTEVat {
    public static final Decimal RATE = 20;
    public static Decimal rate(Decimal savedRate) { return savedRate == null ? RATE : savedRate; }
    public static Decimal tax(Decimal net, Decimal savedRate) {
        return net == null ? null : (net * rate(savedRate) / 100).setScale(2, RoundingMode.HALF_UP);
    }
    public static Decimal gross(Decimal net, Decimal savedRate) {
        return net == null ? null : net + tax(net, savedRate);
    }
    public static Decimal taxFromGross(Decimal grossAmount, Decimal savedRate) {
        Decimal vatRate = rate(savedRate);
        return grossAmount == null ? null : (grossAmount * vatRate / (100 + vatRate)).setScale(2, RoundingMode.HALF_UP);
    }
    public static Decimal netFromGross(Decimal grossAmount, Decimal savedRate) {
        return grossAmount == null ? null : grossAmount - taxFromGross(grossAmount, savedRate);
    }
    public static Decimal bookingGross(Decimal net, Decimal savedRate, Decimal savedAmount) {
        return savedAmount == null ? gross(net, savedRate) : savedAmount;
    }
    public static Decimal bookingTax(Decimal net, Decimal savedRate, Decimal savedAmount) {
        Decimal grossAmount = bookingGross(net, savedRate, savedAmount);
        return net == null || grossAmount == null ? null : grossAmount - net;
    }
    public static Boolean consistentTotal(Decimal net, Decimal savedRate, Decimal grossAmount) {
        return grossAmount == null || gross(net, savedRate) == grossAmount || netFromGross(grossAmount, savedRate) == net;
    }
}
