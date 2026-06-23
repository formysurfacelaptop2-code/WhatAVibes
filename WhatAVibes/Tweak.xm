// WhatAVibes - Tweak.xm
// Hooks into Apple Music to apply custom fonts, colors,
// animated now playing screen, and card-style layouts.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// ─────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────

static UIColor *accentColor() {
    // Electric violet accent — change to any hex you like
    return [UIColor colorWithRed:0.45 green:0.20 blue:1.00 alpha:1.0];
}

static UIColor *bgColor() {
    return [UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:1.0];
}

static UIFont *vibeFont(CGFloat size, BOOL bold) {
    // Uses system rounded (San Francisco Rounded) — feels softer/quirkier
    UIFontDescriptor *desc = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    UIFontDescriptor *rounded = [desc fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    if (bold) {
        rounded = [rounded fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    }
    return [UIFont fontWithDescriptor:rounded size:size];
}

// Adds a looping pulse animation to a view (for album art)
static void addPulseAnimation(UIView *view) {
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @(1.0);
    pulse.toValue   = @(1.04);
    pulse.autoreverses  = YES;
    pulse.repeatCount   = HUGE_VALF;
    pulse.duration      = 1.8;
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:pulse forKey:@"wav_pulse"];
}

// Adds a subtle floating animation (up/down drift)
static void addFloatAnimation(UIView *view) {
    CABasicAnimation *drift = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    drift.fromValue    = @(-4.0);
    drift.toValue      = @(4.0);
    drift.autoreverses = YES;
    drift.repeatCount  = HUGE_VALF;
    drift.duration     = 2.4;
    drift.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:drift forKey:@"wav_float"];
}

// Wraps a view in a card (rounded rect + shadow)
static void applyCardStyle(UIView *view, CGFloat cornerRadius) {
    view.layer.cornerRadius     = cornerRadius;
    view.layer.masksToBounds    = NO;
    view.layer.shadowColor      = accentColor().CGColor;
    view.layer.shadowOpacity    = 0.45;
    view.layer.shadowRadius     = 18.0;
    view.layer.shadowOffset     = CGSizeMake(0, 6);
    view.clipsToBounds          = NO;
}

// Adds an animated gradient background layer
static void addAnimatedGradient(UIView *view) {
    // Remove any existing gradient we added
    for (CALayer *layer in [view.layer.sublayers copy]) {
        if ([layer.name isEqualToString:@"wav_gradient"]) {
            [layer removeFromSuperlayer];
        }
    }

    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.name   = @"wav_gradient";
    grad.frame  = view.bounds;
    grad.colors = @[
        (id)[UIColor colorWithRed:0.08 green:0.04 blue:0.18 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.12 green:0.04 blue:0.22 alpha:1.0].CGColor,
    ];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint   = CGPointMake(1, 1);
    grad.locations  = @[@0.0, @0.5, @1.0];

    // Animate color cycling
    CABasicAnimation *colorAnim = [CABasicAnimation animationWithKeyPath:@"colors"];
    colorAnim.fromValue = grad.colors;
    colorAnim.toValue   = @[
        (id)[UIColor colorWithRed:0.12 green:0.04 blue:0.22 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.08 green:0.04 blue:0.18 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.05 green:0.05 blue:0.10 alpha:1.0].CGColor,
    ];
    colorAnim.duration      = 4.0;
    colorAnim.autoreverses  = YES;
    colorAnim.repeatCount   = HUGE_VALF;
    colorAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [grad addAnimation:colorAnim forKey:@"wav_gradientAnim"];
    [view.layer insertSublayer:grad atIndex:0];
    grad.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
}


// ─────────────────────────────────────────────
// MARK: - Hook: Now Playing Full-Screen Player
// Apple Music's now-playing controller class.
// Class name confirmed via class-dump on iOS 16/17.
// ─────────────────────────────────────────────

%hook MPCFullScreenPlayerViewController

- (void)viewDidLoad {
    %orig;

    UIView *v = self.view;

    // 1. Dark animated gradient background
    addAnimatedGradient(v);
}

- (void)viewDidLayoutSubviews {
    %orig;
    // Re-fit gradient when the view resizes (rotation, etc.)
    for (CALayer *layer in self.view.layer.sublayers) {
        if ([layer.name isEqualToString:@"wav_gradient"]) {
            layer.frame = self.view.bounds;
        }
    }
}

%end


// ─────────────────────────────────────────────
// MARK: - Hook: Album Art Image View
// Hooks the artwork view inside the player to
// add card styling + pulse + float animations.
// ─────────────────────────────────────────────

%hook MPCPlayerFullScreenArtworkView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;

    // Card style with big radius + purple glow shadow
    applyCardStyle(self, 24.0);

    // Animated: pulse scale + gentle float
    [self.layer removeAnimationForKey:@"wav_pulse"];
    [self.layer removeAnimationForKey:@"wav_float"];
    addPulseAnimation(self);
    addFloatAnimation(self);
}

%end


// ─────────────────────────────────────────────
// MARK: - Hook: Track Title & Artist Labels
// ─────────────────────────────────────────────

%hook MPCPlayerFullScreenMetadataView

- (void)layoutSubviews {
    %orig;

    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)sub;

            if (label.font.pointSize >= 18) {
                // Song title — bigger, bold, accent color
                label.font      = vibeFont(22.0, YES);
                label.textColor = [UIColor whiteColor];
                // Add a subtle glow via shadow
                label.layer.shadowColor   = accentColor().CGColor;
                label.layer.shadowOpacity = 0.9;
                label.layer.shadowRadius  = 8.0;
                label.layer.shadowOffset  = CGSizeZero;
            } else {
                // Artist / album subtitle
                label.font      = vibeFont(14.0, NO);
                label.textColor = [accentColor() colorWithAlphaComponent:0.85];
            }
        }
    }
}

%end


// ─────────────────────────────────────────────
// MARK: - Hook: Playback Controls Bar
// Gives the controls a frosted card look.
// ─────────────────────────────────────────────

%hook MPCPlayerFullScreenTransportView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;

    // Frosted glass card
    self.backgroundColor    = [UIColor colorWithWhite:1.0 alpha:0.06];
    self.layer.cornerRadius = 20.0;
    self.clipsToBounds      = YES;

    // Add blur effect behind controls
    UIBlurEffect *blur   = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame              = self.bounds;
    blurView.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurView.layer.cornerRadius = 20.0;
    blurView.clipsToBounds      = YES;
    [self insertSubview:blurView atIndex:0];
}

- (void)layoutSubviews {
    %orig;
    // Tint all button images with accent color
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)sub;
            [btn setTintColor:accentColor()];
            btn.tintColor = accentColor();
        }
    }
}

%end


// ─────────────────────────────────────────────
// MARK: - Hook: Progress / Scrubber Slider
// ─────────────────────────────────────────────

%hook MPCPlayerScrubberView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;

    // Tint the scrubber track & thumb with accent
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UISlider class]]) {
            UISlider *slider = (UISlider *)sub;
            slider.minimumTrackTintColor = accentColor();
            slider.thumbTintColor        = [UIColor whiteColor];
        }
    }
}

%end


// ─────────────────────────────────────────────
// MARK: - Hook: Browse / Library Tab Cells
// Makes list cells look like rounded cards.
// ─────────────────────────────────────────────

%hook MusicTableViewCell

- (void)layoutSubviews {
    %orig;

    self.backgroundColor         = [UIColor colorWithWhite:1.0 alpha:0.05];
    self.layer.cornerRadius      = 14.0;
    self.layer.masksToBounds     = NO;
    self.layer.shadowColor       = accentColor().CGColor;
    self.layer.shadowOpacity     = 0.15;
    self.layer.shadowRadius      = 8.0;
    self.layer.shadowOffset      = CGSizeMake(0, 3);
    self.clipsToBounds           = NO;

    // Rounded image views (album thumbnails)
    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UIImageView class]]) {
            sub.layer.cornerRadius  = 8.0;
            sub.layer.masksToBounds = YES;
        }
        if ([sub isKindOfClass:[UILabel class]]) {
            UILabel *lbl = (UILabel *)sub;
            if (lbl.font.pointSize >= 14) {
                lbl.font = vibeFont(lbl.font.pointSize, YES);
            } else {
                lbl.font = vibeFont(lbl.font.pointSize, NO);
            }
        }
    }
}

%end


// ─────────────────────────────────────────────
// MARK: - Hook: Mini Player Bar
// ─────────────────────────────────────────────

%hook MPMiniPlayerView

- (void)didMoveToWindow {
    %orig;
    if (!self.window) return;

    applyCardStyle(self, 16.0);
    self.backgroundColor = [UIColor colorWithRed:0.10 green:0.06 blue:0.20 alpha:0.92];

    UIBlurEffect *blur        = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    UIVisualEffectView *fx    = [[UIVisualEffectView alloc] initWithEffect:blur];
    fx.frame                  = self.bounds;
    fx.autoresizingMask       = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    fx.layer.cornerRadius     = 16.0;
    fx.clipsToBounds          = YES;
    [self insertSubview:fx atIndex:0];
}

%end
