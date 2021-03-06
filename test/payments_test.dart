@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('send native payment', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    // send 100 XLM native payment from A to C
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountCId, Asset.NATIVE, "100").build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        assert(double.parse(balance.balance) > 100);
        break;
      }
    }

    bool found = false;
    Page<OperationResponse> payments = await sdk.payments
        .forAccount(accountCId)
        .order(RequestBuilderOrder.DESC)
        .execute();
    for (OperationResponse payment in payments.records) {
      if (payment is PaymentOperationResponse) {
        assert(payment.sourceAccount == accountAId);
        found = true;
        break;
      }
    }
    assert(found);
  });

  test('send native payment - muxed source and muxed destination account',
      () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    MuxedAccount muxedDestinationAccount = MuxedAccount(accountCId, 10120291);
    MuxedAccount muxedSourceAccount = MuxedAccount(accountAId, 9999999999);
    PaymentOperation paymentOperation =
        PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedDestinationAccount, Asset.NATIVE, "100")
            .setMuxedSourceAccount(muxedSourceAccount)
            .build();

    // send 100 XLM native payment from A to C

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(paymentOperation)
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    String transactionHash = response.hash;
    print(response.hash);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        assert(double.parse(balance.balance) > 100);
        break;
      }
    }

    bool found = false;
    Page<OperationResponse> payments = await sdk.payments
        .forAccount(accountCId)
        .order(RequestBuilderOrder.DESC)
        .execute();
    for (OperationResponse payment in payments.records) {
      if (payment is PaymentOperationResponse) {
        assert(payment.sourceAccount == accountAId);
        found = true;
        break;
      }
    }
    assert(found);

    found = false;
    Page<TransactionResponse> transactions = await sdk.transactions
        .forAccount(accountCId)
        .order(RequestBuilderOrder.DESC)
        .execute();
    for (TransactionResponse transaction in transactions.records) {
      if (transaction.hash == transactionHash) {
        found = true;
      }
    }
    assert(found);
  });

  test('send native payment with max operation fee', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .setMaxOperationFee(300)
        .build();

    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    // send 100 XLM native payment from A to C
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountCId, Asset.NATIVE, "100").build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        assert(double.parse(balance.balance) > 100);
        break;
      }
    }
  });

  test('send non native payment', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    // fund account B.
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountBId, "10").build())
        .build();

    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperationBuilder chOp =
        ChangeTrustOperationBuilder(iomAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountB = await sdk.accounts.account(accountBId);
    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    // send 100 IOM non native payment from A to C
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountCId, iomAsset, "100").build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    bool found = false;
    accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "IOM") {
        assert(double.parse(balance.balance) > 90);
        found = true;
        break;
      }
    }
    assert(found);

    // send 50.09 IOM non native payment from C to B
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountBId, iomAsset, "50.09").build())
        .build();
    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    found = false;
    accountB = await sdk.accounts.account(accountBId);
    for (Balance balance in accountB.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "IOM") {
        assert(double.parse(balance.balance) > 40);
        found = true;
        break;
      }
    }
    assert(found);
  });

  test('send non native payment with muxed accounts', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;

    MuxedAccount muxedCAccount = MuxedAccount(accountCId, 10120291);
    MuxedAccount muxedAAccount = MuxedAccount(accountAId, 9999999999);

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10")
            .setMuxedSourceAccount(muxedAAccount)
            .build())
        .build();

    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    // fund account B.
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountBId, "10")
            .setMuxedSourceAccount(muxedAAccount)
            .build())
        .build();

    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperationBuilder chOp =
        ChangeTrustOperationBuilder(iomAsset, "200999")
            .setMuxedSourceAccount(muxedCAccount);

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    MuxedAccount muxedBAccount = MuxedAccount(accountBId, 82882999828222);
    chOp = ChangeTrustOperationBuilder(iomAsset, "200999")
        .setMuxedSourceAccount(muxedBAccount);
    AccountResponse accountB = await sdk.accounts.account(accountBId);
    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    PaymentOperation paymentOperation =
        PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedCAccount, iomAsset, "100")
            .setMuxedSourceAccount(muxedAAccount)
            .build();

    // send 100 IOM non native payment from A to C
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(paymentOperation)
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    bool found = false;
    accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "IOM") {
        assert(double.parse(balance.balance) > 90);
        found = true;
        break;
      }
    }
    assert(found);

    paymentOperation = PaymentOperationBuilder.forMuxedDestinationAccount(
            muxedBAccount, iomAsset, "100")
        .setMuxedSourceAccount(muxedCAccount)
        .build();
    // send 50.09 IOM non native payment from C to B
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(paymentOperation)
        .build();
    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    found = false;
    accountB = await sdk.accounts.account(accountBId);
    for (Balance balance in accountB.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "IOM") {
        assert(double.parse(balance.balance) > 40);
        found = true;
        break;
      }
    }
    assert(found);
  });

  test('path payment strict send and strict receive', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .addOperation(
            new CreateAccountOperationBuilder(accountBId, "10").build())
        .addOperation(
            new CreateAccountOperationBuilder(accountDId, "10").build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    AccountResponse accountB = await sdk.accounts.account(accountBId);
    AccountResponse accountD = await sdk.accounts.account(accountDId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", keyPairA.accountId);
    ChangeTrustOperationBuilder ctIOMOp =
        ChangeTrustOperationBuilder(iomAsset, "200999");
    ChangeTrustOperationBuilder ctECOOp =
        ChangeTrustOperationBuilder(ecoAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .build();
    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountD, Network.TESTNET)
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairD);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountCId, iomAsset, "100").build())
        .addOperation(
            PaymentOperationBuilder(accountBId, iomAsset, "100").build())
        .addOperation(
            PaymentOperationBuilder(accountBId, ecoAsset, "100").build())
        .addOperation(
            PaymentOperationBuilder(accountDId, ecoAsset, "100").build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    ManageSellOfferOperation sellOfferOp =
        ManageSellOfferOperation(ecoAsset, iomAsset, "30", "0.5", 0);
    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(sellOfferOp)
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    PathPaymentStrictSendOperation strictSend =
        PathPaymentStrictSendOperationBuilder(
                iomAsset, "10", accountDId, ecoAsset, "18")
            .build();
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(strictSend)
        .build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    bool found = false;
    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 19);
        found = true;
        break;
      }
    }
    assert(found);

    PathPaymentStrictReceiveOperation strictReceive =
        PathPaymentStrictReceiveOperationBuilder(
                iomAsset, "2", accountDId, ecoAsset, "3")
            .build();
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(strictReceive)
        .build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    found = false;
    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 22);
        found = true;
        break;
      }
    }
    assert(found);
  });

  test('path payment strict send and strict receive - muxed accounts',
      () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;

    MuxedAccount muxedAAccount = MuxedAccount(accountAId, 111111111111);
    MuxedAccount muxedBAccount = MuxedAccount(accountBId, 222222222222);
    MuxedAccount muxedCAccount = MuxedAccount(accountCId, 333333333333);
    MuxedAccount muxedDAccount = MuxedAccount(accountDId, 444444444444);

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10")
            .setMuxedSourceAccount(muxedAAccount)
            .build())
        .addOperation(new CreateAccountOperationBuilder(accountBId, "10")
            .setMuxedSourceAccount(muxedAAccount)
            .build())
        .addOperation(new CreateAccountOperationBuilder(accountDId, "10")
            .setMuxedSourceAccount(muxedAAccount)
            .build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    AccountResponse accountB = await sdk.accounts.account(accountBId);
    AccountResponse accountD = await sdk.accounts.account(accountDId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", keyPairA.accountId);
    ChangeTrustOperationBuilder ctIOMOp =
        ChangeTrustOperationBuilder(iomAsset, "200999");
    ChangeTrustOperationBuilder ctECOOp =
        ChangeTrustOperationBuilder(ecoAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .build();
    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountD, Network.TESTNET)
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairD);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedCAccount, iomAsset, "100")
            .build())
        .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedBAccount, iomAsset, "100")
            .build())
        .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedBAccount, ecoAsset, "100")
            .build())
        .addOperation(PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedDAccount, ecoAsset, "100")
            .build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    ManageSellOfferOperation sellOfferOp =
        ManageSellOfferOperationBuilder(ecoAsset, iomAsset, "30", "0.5")
            .setMuxedSourceAccount(muxedBAccount)
            .build();
    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(sellOfferOp)
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    PathPaymentStrictSendOperation strictSend =
        PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
                iomAsset, "10", muxedDAccount, ecoAsset, "18")
            .setMuxedSourceAccount(muxedCAccount)
            .build();
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(strictSend)
        .build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    bool found = false;
    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 19);
        found = true;
        break;
      }
    }
    assert(found);

    PathPaymentStrictReceiveOperation strictReceive =
        PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
                iomAsset, "2", muxedDAccount, ecoAsset, "3")
            .setMuxedSourceAccount(muxedCAccount)
            .build();
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(strictReceive)
        .build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print(response.hash);

    found = false;
    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 22);
        found = true;
        break;
      }
    }
    assert(found);
  });

  test('get payments for account, transaction, ledger', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .addOperation(
            new CreateAccountOperationBuilder(accountBId, "10").build())
        .addOperation(
            new CreateAccountOperationBuilder(accountDId, "10").build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountCId, Asset.NATIVE, "10").build())
        .addOperation(
            PaymentOperationBuilder(accountBId, Asset.NATIVE, "10").build())
        .addOperation(
            PaymentOperationBuilder(accountDId, Asset.NATIVE, "10").build())
        .build();
    transaction.sign(keyPairA);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    Page<OperationResponse> payments = await sdk.payments
        .forAccount(accountAId)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(payments.records.length > 6);

    String createAccTransactionHash;
    String paymentTransactionHash;
    for (OperationResponse response in payments.records) {
      if (response is PaymentOperationResponse &&
          paymentTransactionHash == null) {
        PaymentOperationResponse por = response;
        if (por.transactionSuccessful) {
          paymentTransactionHash = por.transactionHash;
        }
      } else if (response is CreateAccountOperationResponse &&
          createAccTransactionHash == null) {
        CreateAccountOperationResponse car = response;
        if (car.transactionSuccessful) {
          createAccTransactionHash = car.transactionHash;
        }
      }
    }
    assert(paymentTransactionHash != null);
    assert(createAccTransactionHash != null);

    payments =
        await sdk.payments.forTransaction(paymentTransactionHash).execute();
    assert(payments.records.length > 0);

    payments =
        await sdk.payments.forTransaction(createAccTransactionHash).execute();
    assert(payments.records.length > 0);

    TransactionResponse tran =
        await sdk.transactions.transaction(paymentTransactionHash);
    assert(tran.ledger != null);
    payments = await sdk.payments.forLedger(tran.ledger).execute();
    assert(payments.records.length > 0);
  });

  test('stream payments', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(accountAId);

    KeyPair keyPairB = KeyPair.random();
    String accountBId = keyPairB.accountId;

    // fund account B.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountBId, "1000").build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse accountB = await sdk.accounts.account(accountBId);

    String amount = "10";
    bool paymentReceived = false;

    // Stream.
    var subscription = sdk.payments
        .forAccount(accountAId)
        .cursor("now")
        .stream()
        .listen((response) {
      if (response is PaymentOperationResponse &&
          response.assetType == Asset.TYPE_NATIVE &&
          response.sourceAccount == accountBId &&
          double.parse(response.amount) == double.parse(amount)) {
        paymentReceived = true;
      }
    });

    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountAId, Asset.NATIVE, amount).build())
        .build();
    transaction.sign(keyPairB);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    // wait 3 seconds for the payment event.
    await Future.delayed(const Duration(seconds: 3), () {});
    subscription.cancel();
    assert(paymentReceived);
  });
}
