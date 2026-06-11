import GoogleMobileAds
import SwiftUI

// Built-in native ad templates. Visual parity targets are the v2 UIKit/XIB
// implementations; metric comments below reference those originals.

/// `.card`: media on top (16:9), icon + headline + rating row, body, CTA.
struct NativeAdCardTemplate: View {
    let assets: NativeAdAssets

    private static let ctaBlue = Color(red: 56 / 255, green: 113 / 255, blue: 224 / 255)

    var body: some View {
        VStack(spacing: 0) {
            assets.media
                .aspectRatio(16.0 / 9.0, contentMode: .fit)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    assets.icon?
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 8) {
                        assets.headline
                            .font(.system(size: 17, weight: .medium))
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            AdBadge()
                            assets.starRating?
                                .frame(width: 100, height: 17)
                            assets.advertiser
                                .font(.system(size: 14))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)
                }

                assets.body
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                assets.callToAction
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 39)
                    .background(Self.ctaBlue)
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
            }
            .padding(10)
        }
    }
}

/// `.banner`: compact text-only row with the app icon on the right.
struct NativeAdBannerTemplate: View {
    let assets: NativeAdAssets

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    assets.headline
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                    AdBadge()
                }
                assets.body
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            assets.icon?
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(8)
    }
}

/// `.largeBanner`: media on the left (16:9), text column + CTA on the right,
/// subtle "Ad" badge overlaid in the top-leading corner.
struct NativeAdLargeBannerTemplate: View {
    let assets: NativeAdAssets

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(alignment: .center, spacing: 8) {
                assets.media
                    .aspectRatio(assets.mediaAspectRatio >= 1 ? assets.mediaAspectRatio : 1,
                                 contentMode: .fit)
                    .frame(height: 120)

                VStack(alignment: .leading, spacing: 4) {
                    assets.headline
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(2)
                    assets.advertiser
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    assets.body
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    // v2 hid the CTA whenever body text was present.
                    if assets.ad.body?.isEmpty != false {
                        assets.callToAction
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemBlue))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.trailing, 8)

            AdBadge(foregroundColor: .secondary,
                    backgroundColor: Color(.systemFill),
                    cornerRadius: 4)
                .padding(4)
        }
    }
}

/// `.basic`: the former XIB layout — icon + headline header, full body text,
/// centered media, price/store/CTA footer row.
struct NativeAdBasicTemplate: View {
    let assets: NativeAdAssets

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    assets.icon?
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    VStack(alignment: .leading, spacing: 4) {
                        assets.headline
                            .font(.system(size: 17))
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            assets.advertiser
                                .font(.system(size: 14))
                                .lineLimit(1)
                            assets.starRating?
                                .frame(width: 100, height: 17)
                        }
                    }
                }

                assets.body
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)

                assets.media
                    .frame(width: 250, height: 150)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    Spacer()
                    assets.price
                        .font(.system(size: 14))
                    assets.store
                        .font(.system(size: 14))
                    assets.callToAction
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemBlue))
                        .cornerRadius(6)
                }
            }
            .padding(EdgeInsets(top: 10, leading: 15, bottom: 20, trailing: 15))

            AdBadge(backgroundColor: Color(red: 1, green: 0.8, blue: 0.4),
                    cornerRadius: 0)
        }
        .background(Color(.secondarySystemBackground))
    }
}
