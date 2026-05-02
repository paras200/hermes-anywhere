#!/usr/bin/env python3
"""Portfolio management — paper trading record keeper for Alpha Desk."""

import sys
import json
import os
from datetime import datetime

DATA_DIR = os.path.expanduser("~/.hermes/skills/finance/alpha-desk/data")
PORTFOLIO_FILE = os.path.join(DATA_DIR, "portfolio.json")
DECISIONS_FILE = os.path.join(DATA_DIR, "decisions_log.json")

DEFAULT_PORTFOLIO = {
    "portfolio_name": "Alpha Desk",
    "base_currency": "USD",
    "created_at": datetime.now().strftime("%Y-%m-%d"),
    "initial_capital": 100000,
    "cash": 100000,
    "holdings": [],
    "transactions": [],
    "strategy_version": 1,
}


def ensure_data_dir():
    os.makedirs(DATA_DIR, exist_ok=True)


def load_portfolio():
    ensure_data_dir()
    if os.path.exists(PORTFOLIO_FILE):
        with open(PORTFOLIO_FILE) as f:
            return json.load(f)
    return DEFAULT_PORTFOLIO.copy()


def save_portfolio(pf):
    ensure_data_dir()
    with open(PORTFOLIO_FILE, "w") as f:
        json.dump(pf, f, indent=2)


def log_decision(decision):
    ensure_data_dir()
    log = []
    if os.path.exists(DECISIONS_FILE):
        with open(DECISIONS_FILE) as f:
            log = json.load(f)
    log.append(decision)
    with open(DECISIONS_FILE, "w") as f:
        json.dump(log, f, indent=2)


def buy(symbol, shares, price, thesis="", target=None, stop_loss=None, sector="", confidence="medium", time_horizon=""):
    pf = load_portfolio()
    cost = shares * price

    if cost > pf["cash"]:
        return {"error": f"Insufficient cash. Need ${cost:.2f}, have ${pf['cash']:.2f}"}

    # Check position size limits
    total_value = pf["cash"] + sum(h["shares"] * h["avg_cost"] for h in pf["holdings"])
    if cost / total_value > 0.15:
        return {"error": f"Position too large ({cost/total_value*100:.1f}% of portfolio). Max 15%."}

    pf["cash"] -= cost

    existing = next((h for h in pf["holdings"] if h["symbol"] == symbol), None)
    if existing:
        total_shares = existing["shares"] + shares
        existing["avg_cost"] = (
            (existing["avg_cost"] * existing["shares"]) + (price * shares)
        ) / total_shares
        existing["shares"] = total_shares
        if thesis:
            existing["thesis"] = thesis
    else:
        market = "IN" if (".NS" in symbol or ".BO" in symbol) else "US"
        holding = {
            "symbol": symbol,
            "market": market,
            "shares": shares,
            "avg_cost": price,
            "bought_at": datetime.now().strftime("%Y-%m-%d"),
            "thesis": thesis,
            "target_price": target,
            "stop_loss": stop_loss,
            "time_horizon": time_horizon,
            "sector": sector,
            "confidence": confidence,
        }
        pf["holdings"].append(holding)

    tx = {
        "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "action": "BUY",
        "symbol": symbol,
        "shares": shares,
        "price": price,
        "cost": cost,
        "reasoning": thesis,
        "confidence": confidence,
    }
    pf["transactions"].append(tx)
    save_portfolio(pf)

    log_decision({
        "type": "trade",
        "date": tx["date"],
        "action": "BUY",
        "symbol": symbol,
        "shares": shares,
        "price": price,
        "thesis": thesis,
        "confidence": confidence,
        "target": target,
        "stop_loss": stop_loss,
    })

    return {"status": "bought", "symbol": symbol, "shares": shares, "price": price, "remaining_cash": round(pf["cash"], 2)}


def sell(symbol, shares, price, reason=""):
    pf = load_portfolio()
    holding = next((h for h in pf["holdings"] if h["symbol"] == symbol), None)

    if not holding:
        return {"error": f"No holding found for {symbol}"}
    if shares > holding["shares"]:
        return {"error": f"Only hold {holding['shares']} shares of {symbol}"}

    proceeds = shares * price
    pf["cash"] += proceeds

    pnl = (price - holding["avg_cost"]) * shares
    pnl_pct = ((price - holding["avg_cost"]) / holding["avg_cost"]) * 100

    holding["shares"] -= shares
    original_thesis = holding.get("thesis", "")
    if holding["shares"] == 0:
        pf["holdings"].remove(holding)

    tx = {
        "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "action": "SELL",
        "symbol": symbol,
        "shares": shares,
        "price": price,
        "proceeds": proceeds,
        "pnl": round(pnl, 2),
        "pnl_pct": round(pnl_pct, 2),
        "reasoning": reason,
    }
    pf["transactions"].append(tx)
    save_portfolio(pf)

    log_decision({
        "type": "trade",
        "date": tx["date"],
        "action": "SELL",
        "symbol": symbol,
        "shares": shares,
        "price": price,
        "pnl": round(pnl, 2),
        "pnl_pct": round(pnl_pct, 2),
        "reason": reason,
        "original_thesis": original_thesis,
        "thesis_correct": None,  # To be filled in weekly review
    })

    return {
        "status": "sold",
        "symbol": symbol,
        "shares": shares,
        "price": price,
        "pnl": round(pnl, 2),
        "pnl_pct": round(pnl_pct, 2),
        "cash": round(pf["cash"], 2),
    }


def show():
    pf = load_portfolio()
    return {
        "name": pf["portfolio_name"],
        "cash": round(pf["cash"], 2),
        "initial_capital": pf["initial_capital"],
        "num_holdings": len(pf["holdings"]),
        "holdings": pf["holdings"],
        "total_transactions": len(pf["transactions"]),
        "strategy_version": pf.get("strategy_version", 1),
    }


def value():
    pf = load_portfolio()
    total_invested = sum(h["shares"] * h["avg_cost"] for h in pf["holdings"])
    total_portfolio = pf["cash"] + total_invested
    return_pct = ((total_portfolio - pf["initial_capital"]) / pf["initial_capital"]) * 100

    return {
        "cash": round(pf["cash"], 2),
        "invested": round(total_invested, 2),
        "total_portfolio": round(total_portfolio, 2),
        "total_return": round(total_portfolio - pf["initial_capital"], 2),
        "return_pct": round(return_pct, 2),
        "holdings": [
            {
                "symbol": h["symbol"],
                "shares": h["shares"],
                "avg_cost": h["avg_cost"],
                "invested": round(h["shares"] * h["avg_cost"], 2),
                "target": h.get("target_price"),
                "stop_loss": h.get("stop_loss"),
                "confidence": h.get("confidence", "medium"),
            }
            for h in pf["holdings"]
        ],
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: portfolio.py <command> [args]")
        print("Commands: show, value, buy, sell, history")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "show":
        result = show()
    elif cmd == "value":
        result = value()
    elif cmd == "buy" and len(sys.argv) >= 5:
        symbol = sys.argv[2]
        shares = int(sys.argv[3])
        price = float(sys.argv[4])
        kwargs = {}
        for flag in ["--thesis", "--target", "--stop-loss", "--sector", "--confidence", "--horizon"]:
            if flag in sys.argv:
                idx = sys.argv.index(flag)
                key = flag.lstrip("-").replace("-", "_")
                if key == "horizon":
                    key = "time_horizon"
                val = sys.argv[idx + 1]
                if flag in ("--target", "--stop-loss"):
                    val = float(val)
                kwargs[key] = val
        result = buy(symbol, shares, price, **kwargs)
    elif cmd == "sell" and len(sys.argv) >= 5:
        symbol = sys.argv[2]
        shares = int(sys.argv[3])
        price = float(sys.argv[4])
        reason = ""
        if "--reason" in sys.argv:
            idx = sys.argv.index("--reason")
            reason = sys.argv[idx + 1]
        result = sell(symbol, shares, price, reason)
    elif cmd == "history":
        pf = load_portfolio()
        result = pf.get("transactions", [])[-20:]
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
