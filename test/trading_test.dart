@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('manage buy offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair buyerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String buyerAccountId = buyerKeipair.accountId;

    await FriendBot.fundTestAccount(buyerAccountId);

    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(caob.build())
        .build();
    transaction.sign(buyerKeipair);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(astroDollar, "10000");
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ctob.build())
        .build();
    transaction.sign(buyerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String amountBuying = "100";
    String price = "0.5";

    ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(buyerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers =
        (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    double offerAmount = double.parse(offer.amount);
    double offerPrice = double.parse(offer.price);
    double buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller.accountId == buyerKeipair.accountId);

    int offerId = offer.id;

    // update offer
    amountBuying = "150";
    price = "0.3";
    ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(buyerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    offerAmount = double.parse(offer.amount);
    offerPrice = double.parse(offer.price);
    buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller.accountId == buyerAccountId);

    // delete offer
    amountBuying = "0";
    ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(buyerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 0);
  });

  test('manage sell offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair sellerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String sellerAccountId = sellerKeipair.accountId;

    await FriendBot.fundTestAccount(sellerAccountId);

    AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
    CreateAccountOperation co =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(co)
        .build();
    transaction.sign(sellerKeipair);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    Asset moonDollar = AssetTypeCreditAlphaNum4("MOON", issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(moonDollar, "10000");
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ctob.build())
        .build();
    transaction.sign(sellerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, moonDollar, "2000").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String amountSelling = "100";
    String price = "0.5";

    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(sellerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers =
        (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == moonDollar);

    double offerAmount = double.parse(offer.amount);
    double sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    double offerPrice = double.parse(offer.price);
    double sellingPrice = double.parse(price);
    assert(offerPrice == sellingPrice);

    assert(offer.seller.accountId == sellerAccountId);

    int offerId = offer.id;

    // update offer
    amountSelling = "150";
    price = "0.3";
    ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(sellerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == moonDollar);

    offerAmount = double.parse(offer.amount);
    sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    offerPrice = double.parse(offer.price);
    sellingPrice = double.parse(price);

    assert(offerPrice == sellingPrice);

    assert(offer.seller.accountId == sellerAccountId);

    // delete offer
    amountSelling = "0";
    ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(sellerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 0);
  });

  test('create passive sell offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair sellerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String sellerAccountId = sellerKeipair.accountId;

    await FriendBot.fundTestAccount(sellerAccountId);

    AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
    CreateAccountOperation co =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(co)
        .build();
    transaction.sign(sellerKeipair);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    Asset marsDollar = AssetTypeCreditAlphaNum4("MARS", issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(marsDollar, "10000");
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ctob.build())
        .build();
    transaction.sign(sellerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, marsDollar, "2000").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String amountSelling = "100";
    String price = "0.5";

    CreatePassiveSellOfferOperation cpso =
        CreatePassiveSellOfferOperationBuilder(
                marsDollar, Asset.NATIVE, amountSelling, price)
            .build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(cpso)
        .build();
    transaction.sign(sellerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers =
        (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == marsDollar);

    double offerAmount = double.parse(offer.amount);
    double sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    double offerPrice = double.parse(offer.price);
    double sellingPrice = double.parse(price);
    assert(offerPrice == sellingPrice);

    assert(offer.seller.accountId == sellerAccountId);

    int offerId = offer.id;

    // update offer
    amountSelling = "150";
    price = "0.3";
    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(sellerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == marsDollar);

    offerAmount = double.parse(offer.amount);
    sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    offerPrice = double.parse(offer.price);
    sellingPrice = double.parse(price);

    assert(offerPrice == sellingPrice);

    assert(offer.seller.accountId == sellerAccountId);

    // delete offer
    amountSelling = "0";
    ms = ManageSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(sellerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 0);
  });
}
