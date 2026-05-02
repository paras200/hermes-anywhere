#!/usr/bin/env python3
"""Fetch market data for US and Indian stocks using yfinance."""

import sys
import json
import subprocess


def ensure_yfinance():
    try:
        import yfinance  # noqa: F401
    except ImportError:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--quiet", "yfinance"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def get_price(symbol):
    import yfinance as yf

    ticker = yf.Ticker(symbol)
    info = ticker.fast_info
    hist = ticker.history(period="2d")
    if hist.empty:
        return {"error": f"No data for {symbol}"}

    current = hist["Close"].iloc[-1]
    prev = hist["Close"].iloc[-2] if len(hist) > 1 else current
    change_pct = ((current - prev) / prev) * 100

    return {
        "symbol": symbol,
        "price": round(current, 2),
        "previous_close": round(prev, 2),
        "change_pct": round(change_pct, 2),
        "currency": info.currency if hasattr(info, "currency") else "USD",
        "market_cap": getattr(info, "market_cap", None),
    }


def get_history(symbol, period="1mo"):
    import yfinance as yf

    ticker = yf.Ticker(symbol)
    hist = ticker.history(period=period)
    if hist.empty:
        return {"error": f"No data for {symbol}"}

    records = []
    for date, row in hist.iterrows():
        records.append(
            {
                "date": date.strftime("%Y-%m-%d"),
                "open": round(row["Open"], 2),
                "high": round(row["High"], 2),
                "low": round(row["Low"], 2),
                "close": round(row["Close"], 2),
                "volume": int(row["Volume"]),
            }
        )
    return {"symbol": symbol, "period": period, "data": records}


def get_multiple(symbols):
    results = []
    for s in symbols:
        results.append(get_price(s))
    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: market_data.py <command> [args]")
        print("Commands: price <SYMBOL>, history <SYMBOL> [--period 1mo], multi <SYM1,SYM2,...>")
        sys.exit(1)

    ensure_yfinance()
    cmd = sys.argv[1]

    if cmd == "price" and len(sys.argv) >= 3:
        result = get_price(sys.argv[2])
    elif cmd == "history" and len(sys.argv) >= 3:
        period = "1mo"
        if "--period" in sys.argv:
            idx = sys.argv.index("--period")
            period = sys.argv[idx + 1]
        result = get_history(sys.argv[2], period)
    elif cmd == "multi" and len(sys.argv) >= 3:
        symbols = sys.argv[2].split(",")
        result = get_multiple(symbols)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
