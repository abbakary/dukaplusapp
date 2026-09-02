class OfflineMessages {
  static String offlineBanner(bool isSw, int pendingCount) {
    if (pendingCount > 0) {
      return isSw
          ? 'Huna mtandao. Mabadiliko $pendingCount yamehifadhiwa na yatasawazishwa ukirudi mtandaoni.'
          : "You're offline. $pendingCount change(s) saved and will sync when back online.";
    }
    return isSw
        ? 'Huna mtandao — unaendelea na data iliyohifadhiwa kwenye kifaa chako.'
        : "You're offline — continuing with data saved on this device.";
  }

  static String backOnline(bool isSw) =>
      isSw ? 'Umerudi mtandaoni — data zinasawazishwa…' : 'Back online — syncing your data…';

  static String saleQueued(bool isSw) => isSw
      ? 'Mauzo yamehifadhiwa kwenye kifaa. Yatasawazishwa ukirudi mtandaoni.'
      : 'Sale saved on device. It will sync when you\'re back online.';

  static String mutationQueued(bool isSw, String type) {
    switch (type) {
      case 'product':
        return isSw
            ? 'Bidhaa imehifadhiwa — itasawazishwa ukirudi mtandaoni.'
            : 'Product saved locally — will sync when back online.';
      case 'customer':
        return isSw
            ? 'Mteja amehifadhiwa — itasawazishwa ukirudi mtandaoni.'
            : 'Customer saved locally — will sync when back online.';
      case 'stock':
        return isSw
            ? 'Stoo imehifadhiwa — itasawazishwa ukirudi mtandaoni.'
            : 'Stock change saved locally — will sync when back online.';
      default:
        return isSw
            ? 'Imehifadhiwa — itasawazishwa ukirudi mtandaoni.'
            : 'Saved locally — will sync when back online.';
    }
  }

  static String syncSuccess(bool isSw, int count) => isSw
      ? 'Imefanikiwa! Mabadiliko $count yamesawazishwa.'
      : 'Success! $count change(s) synced.';
}
