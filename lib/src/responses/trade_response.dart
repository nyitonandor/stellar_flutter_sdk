// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import '../key_pair.dart';
import '../price.dart';
import 'response.dart';

/// Represents trades response from the horizon server.
/// See: <a href="https://www.stellar.org/developers/horizon/reference/endpoints/trades.html" target="_blank">Trades documentation</a>
class TradeResponse extends Response {
  String id;
  String pagingToken;
  String ledgerCloseTime;
  String offerId;
  bool baseIsSeller;

  KeyPair baseAccount;
  String baseOfferId;
  String baseAmount;
  String baseAssetType;
  String baseAssetCode;
  String baseAssetIssuer;

  KeyPair counterAccount;
  String counterOfferId;
  String counterAmount;
  String counterAssetType;
  String counterAssetCode;
  String counterAssetIssuer;

  Price price;

  TradeResponseLinks links;

  TradeResponse(
      this.id,
      this.pagingToken,
      this.ledgerCloseTime,
      this.offerId,
      this.baseIsSeller,
      this.baseAccount,
      this.baseOfferId,
      this.baseAmount,
      this.baseAssetType,
      this.baseAssetCode,
      this.baseAssetIssuer,
      this.counterAccount,
      this.counterOfferId,
      this.counterAmount,
      this.counterAssetType,
      this.counterAssetCode,
      this.counterAssetIssuer,
      this.price);

  Asset get baseAsset {
    return Asset.create(
        this.baseAssetType, this.baseAssetCode, this.baseAssetIssuer);
  }

  Asset get counterAsset {
    return Asset.create(
        this.counterAssetType, this.counterAssetCode, this.counterAssetIssuer);
  }

  factory TradeResponse.fromJson(Map<String, dynamic> json) =>
      new TradeResponse(
          json['id'] as String,
          json['paging_token'] as String,
          json['ledger_close_time'] as String,
          json['offer_id'] as String,
          json['base_is_seller'] as bool,
          json['base_account'] == null
              ? null
              : KeyPair.fromAccountId(json['base_account'] as String),
          json['base_offer_id'] as String,
          json['base_amount'] as String,
          json['base_asset_type'] as String,
          json['base_asset_code'] as String,
          json['base_asset_issuer'] as String,
          json['counter_account'] == null
              ? null
              : KeyPair.fromAccountId(json['counter_account'] as String),
          json['counter_offer_id'] as String,
          json['counter_amount'] as String,
          json['counter_asset_type'] as String,
          json['counter_asset_code'] as String,
          json['counter_asset_issuer'] as String,
          json['price'] == null
              ? null
              : new Price.fromJson(json['price'] as Map<String, dynamic>))
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset'])
        ..links = json['_links'] == null
            ? null
            : new TradeResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

/// Links connected to a trade response from the horizon server.
class TradeResponseLinks {
  Link base;
  Link counter;
  Link operation;

  TradeResponseLinks(this.base, this.counter, this.operation);

  factory TradeResponseLinks.fromJson(Map<String, dynamic> json) =>
      new TradeResponseLinks(
          json['base'] == null
              ? null
              : new Link.fromJson(json['base'] as Map<String, dynamic>),
          json['counter'] == null
              ? null
              : new Link.fromJson(json['counter'] as Map<String, dynamic>),
          json['operation'] == null
              ? null
              : new Link.fromJson(json['operation'] as Map<String, dynamic>));
}
