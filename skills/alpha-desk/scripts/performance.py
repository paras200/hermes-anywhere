#!/usr/bin/env python3
"""Portfolio performance analytics and self-improvement for Alpha Desk."""

import sys
import json
import os
from datetime import datetime

DATA_DIR = os.path.expanduser("~/.hermes/skills/finance/alpha-desk/data")
PORTFOLIO_FILE = os.path.join(DATA_DIR, "portfolio.json")
DECISIONS_FILE = os.path.join(DATA_DIR, "decisions_log.json")


def load_json(path):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return None


def summary():
    pf = load_json(PORTFOLIO_FILE)
    if not pf:
        return {"error": "No portfolio found. Initialize first."}

    total_invested = sum(h["shares"] * h["avg_cost"] for h in pf["holdings"])
    total_value = pf["cash"] + total_invested
    total_return = total_value - pf["initial_capital"]
    return_pct = (total_return / pf["initial_capital"]) * 100

    sells = [t for t in pf["transactions"] if t["action"] == "SELL"]
    wins = [t for t in sells if t.get("pnl", 0) > 0]
    losses = [t for t in sells if t.get("pnl", 0) < 0]
    breakeven = [t for t in sells if t.get("pnl", 0) == 0]

    avg_win = sum(t["pnl"] for t in wins) / len(wins) if wins else 0
    avg_loss = sum(t["pnl"] for t in losses) / len(losses) if losses else 0

    return {
        "portfolio_name": pf["portfolio_name"],
        "initial_capital": pf["initial_capital"],
        "current_value": round(total_value, 2),
        "cash": round(pf["cash"], 2),
        "invested": round(total_invested, 2),
        "total_return": round(total_return, 2),
        "return_pct": round(return_pct, 2),
        "num_holdings": len(pf["holdings"]),
        "closed_trades": len(sells),
        "wins": len(wins),
        "losses": len(losses),
        "breakeven": len(breakeven),
        "win_rate": round(len(wins) / len(sells) * 100, 1) if sells else 0,
        "avg_win": round(avg_win, 2),
        "avg_loss": round(avg_loss, 2),
        "risk_reward_realized": round(abs(avg_win / avg_loss), 2) if avg_loss != 0 else 0,
        "total_realized_pnl": round(sum(t.get("pnl", 0) for t in sells), 2),
        "largest_win": round(max((t.get("pnl", 0) for t in sells), default=0), 2),
        "largest_loss": round(min((t.get("pnl", 0) for t in sells), default=0), 2),
        "strategy_version": pf.get("strategy_version", 1),
    }


def weekly_review():
    decisions = load_json(DECISIONS_FILE)
    if not decisions:
        return {"error": "No decisions logged yet."}

    trades = [d for d in decisions if d.get("type") == "trade"]
    sells = [d for d in trades if d.get("action") == "SELL"]
    skips = [d for d in decisions if d.get("type") == "skip"]

    review = {
        "type": "weekly_review",
        "date": datetime.now().strftime("%Y-%m-%d"),
        "total_decisions": len(decisions),
        "total_trades": len(trades),
        "total_skips": len(skips),
        "closed_trades": len(sells),
    }

    if sells:
        wins = [s for s in sells if s.get("pnl", 0) > 0]
        losses = [s for s in sells if s.get("pnl", 0) <= 0]

        avg_win = sum(s["pnl"] for s in wins) / len(wins) if wins else 0
        avg_loss = sum(s["pnl"] for s in losses) / len(losses) if losses else 0

        review.update({
            "win_rate": round(len(wins) / len(sells) * 100, 1),
            "avg_win": round(avg_win, 2),
            "avg_loss": round(avg_loss, 2),
            "risk_reward_realized": round(abs(avg_win / avg_loss), 2) if avg_loss != 0 else 0,
            "top_winner": max(sells, key=lambda x: x.get("pnl", 0)),
            "top_loser": min(sells, key=lambda x: x.get("pnl", 0)),
        })

        # Generate improvement suggestions
        suggestions = []
        if review["win_rate"] < 40:
            suggestions.append("CRITICAL: Win rate below 40%. Tighten entry criteria. Review thesis quality.")
        elif review["win_rate"] < 50:
            suggestions.append("Win rate below 50%. Consider stricter filters or better timing.")

        if review["risk_reward_realized"] < 1.5:
            suggestions.append("Risk/reward below 1.5:1. Set wider targets or tighter stops.")
        elif review["risk_reward_realized"] < 2:
            suggestions.append("Risk/reward below 2:1. Room to improve — let winners run longer.")

        if len(losses) > 0 and any(abs(l.get("pnl_pct", 0)) > 15 for l in losses):
            suggestions.append("Some losses exceed 15%. Stop losses may be too wide or not being honored.")

        if not suggestions:
            suggestions.append("Strategy performing within parameters. Maintain current approach.")

        review["suggestions"] = suggestions
    else:
        review["suggestions"] = ["No closed trades to review yet. Continue building positions."]

    # Log the review
    decisions.append(review)
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(DECISIONS_FILE, "w") as f:
        json.dump(decisions, f, indent=2)

    return review


def main():
    if len(sys.argv) < 2:
        print("Usage: performance.py <command>")
        print("Commands: summary, weekly-review")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "summary":
        result = summary()
    elif cmd == "weekly-review":
        result = weekly_review()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
