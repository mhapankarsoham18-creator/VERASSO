/// Represents a financial asset held by a user.
class Asset {
  /// The ticker symbol (e.g., BTC, AAPL).
  final String symbol;

  /// The full name of the asset.
  final String name;

  /// Total units owned.
  final double units;

  /// Weighted average purchase price.
  final double avgPrice;

  /// Creates an [Asset] instance.
  Asset({
    required this.symbol,
    required this.name,
    required this.units,
    required this.avgPrice,
  });
}

/// Market metadata for a specific asset.
class AssetMetadata {
  /// The ticker symbol.
  final String symbol;

  /// The full name.
  final String name;

  /// Current market price.
  final double price;

  /// Price change (absolute or percentage).
  final double change;

  /// The industrial or economic sector.
  final String sector;

  /// Creates an [AssetMetadata] instance.
  AssetMetadata({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.sector,
  });
}

/// Represents a buy or sell transaction of an asset.
class AssetTransaction {
  /// Type of transaction (buy or sell).
  final AssetTransactionType type;

  /// The ticker symbol.
  final String symbol;

  /// Number of units traded.
  final double units;

  /// Price per unit at the time of trade.
  final double price;

  /// Timestamp of the transaction.
  final DateTime date;

  /// Creates an [AssetTransaction] instance.
  AssetTransaction({
    required this.type,
    required this.symbol,
    required this.units,
    required this.price,
    required this.date,
  });
}

/// Enumeration of possible asset transaction types.
enum AssetTransactionType {
  /// Purchase of an asset.
  buy,

  /// Sale of an asset.
  sell
}

/// Represents an event that impacts the market or specific assets.
class MarketEvent {
  /// Title of the event.
  final String title;

  /// Detailed description of what happened.
  final String description;

  /// Qualitative impact (e.g., "High", "Low").
  final String impact;

  /// Timestamp when the event occurred.
  final DateTime date;

  /// Creates a [MarketEvent] instance.
  MarketEvent({
    required this.title,
    required this.description,
    required this.impact,
    required this.date,
  });
}
