# VERSZ APP — FULL REDESIGN MASTER PROMPT

## MISSION
Completely redesign and rebuild every remaining screen and component of the Versz Flutter app to be **10/10 UI/UX** — unique, Gen-Z cool, alpha-millennial hybrid aesthetic. No cookie-cutter design. Every screen must be distinct yet cohesive, with animations throughout and zero placeholder work.

---

## DESIGN SYSTEM — NON-NEGOTIABLE

### Color Tokens (already in `app_colors.dart`)
```
Background:   #090B11  (primaryBlack)
Card:         #101523  (darkCardBg)
Surface:      #161C2D  (darkSurface)
Border:       #2A3550  (darkBorder)
Text primary: #F7FAFF  (darkText)
Text muted:   #95A2B8  (darkTextMuted)

BRAND:
  primaryYellow  = #FFD54A   ← primary action color
  accentBlue     = #23D5FF   ← info / message / link
  accentTeal     = #18E7B2   ← agree / success / join
  accentOrange   = #FF7A18   ← warning / save
  errorRed       = #FF4D73   ← disagree / error / live
```

### Typography
- Display titles: `AppTextStyles.h1` — extra-bold, tight letter spacing
- Labels/tags: `AppTextStyles.labelMedium` — 1.5–2× letter spacing, all caps preferred
- Body: `AppTextStyles.bodyMedium` — 1.5 line height, readable

### Motion / Animation Rules
- **Page entry**: `FadeTransition` + `SlideTransition(Offset(0, 0.04))` — 350ms easeOut
- **List items**: staggered fade-in with 40ms per-item delay
- **Loading skeletons**: shimmer using `AnimationController` looping, colors `darkSurface → darkBorder`
- **Buttons**: scale bounce on press: `Transform.scale(scale: 0.94)` during down, spring back
- **Bottom sheet open**: curved slide-up 280ms
- **Neon glow pulse**: `AnimationController` with `Tween(0.3, 0.7)` on `boxShadow` alpha — used on live badges, active icons

### Unique Design Signature Elements
- **Glitch scanline accent**: subtle diagonal repeating-gradient overlay on hero banners (`Colors.white.withOpacity(0.015)` stripes at 45°)
- **Neon border cards**: `BoxShadow` with spread 0, blur 12–20 using brand color at 20–40% alpha
- **Frosted input bars**: `BackdropFilter` + `ImageFilter.blur(sigmaX:18)` for comment/message input areas
- **Chip/tag style**: rounded pill `BorderRadius.circular(999)` with neon border, NOT filled
- **Avatar frames**: thin neon ring (2px) + outer glow shadow
- **Section headers**: left-aligned, ALL CAPS, `letterSpacing: 2.5`, with a colored 2px left-border accent (`Container(width:3, height:20, color:accentTeal)` + SizedBox(8)`)

---

## NAVIGATION BAR — COMPLETE REBUILD

**File**: `lib/screens/main/home_shell.dart`

### Requirements
The navigation bar must be custom-painted — do NOT use Flutter's default `BottomNavigationBar` or `NavigationBar`. Build it from scratch using a `Container` + `Row`.

### Design Spec
```
Height: 72px + MediaQuery.padding.bottom
Background: darkCardBg with top border darkBorder (1px)
           + very subtle blur: BackdropFilter ImageFilter.blur(sigmaX:20, sigmaY:20)

For each of the 5 tabs (Feed, Search, Create, Chat, Profile):
  INACTIVE:
    Icon: 26px, color: darkTextMuted
    Label: hidden (no label for inactive to keep it clean)
  
  ACTIVE:
    Icon: 26px, color based on tab:
      Feed   → primaryYellow
      Search → accentBlue
      Create → errorRed  (special — see below)
      Chat   → accentTeal
      Profile→ primaryYellow
    Label: ALL CAPS, 9px, letterSpacing:1.2, appear with FadeTransition
    Active indicator: small pill (24×3px) above icon, same color, rounded

  CREATE TAB (index 2) — SPECIAL:
    Render as a floating button INSERT in the center of the nav bar:
      Size: 52×52px circle
      Gradient: LinearGradient primaryYellow → accentOrange (135°)
      Icon: Icons.add_rounded, size:28, color: primaryBlack
      BoxShadow: primaryYellow withAlpha(0.5) blurRadius 20
      On tap: push to /create route
      Has subtle pulse animation (scale 1.0 → 1.06 → 1.0, 2s loop)

  Notification badge on Chat tab:
    Red dot Positioned top-right of icon
    Reads from notificationProvider.unreadCount
    Wobble animation when unreadCount > 0 changes
```

### Utility Drawer (stays)
Keep existing drawer but restyle:
- `drawerScrimColor` transparent
- Drawer width: 80% of screen
- Background: darkCardBg with subtle left-side neon gradient strip
- Each item: icon + label, `accentTeal` icon tint, no dividers, just spacing

---

## SCREENS TO REDESIGN — COMPLETE SPECIFICATIONS

---

### 1. SEARCH SCREEN (`lib/screens/main/search_screen.dart`)

**Concept**: Instagram Explore meets Twitter Search — dark, immersive, content-heavy

#### Layout
```
SafeArea top
│
├── STICKY SEARCH BAR (always visible, not in SliverAppBar)
│     Glass effect: blur + darkCardBg/70
│     Height: 56px, full width, horizontal padding 16
│     Left: search icon (accentBlue, 20px)
│     TextField: hint "Search debates, people, topics..."
│             hint color: textMuted, text: textPrimary
│             border: NONE on field itself (outer Container handles it)
│     Right: X clear button (only when query not empty) + filter icon
│     Container decoration:
│       color: darkSurface
│       borderRadius: 14px
│       border: 1px darkBorder
│
├── TABS (below search bar, NOT SliverAppBar bottom)
│     5 tabs: ALL • DEBATES • PEOPLE • TOPICS • ROOMS
│     Style: horizontal scrollable pill tabs
│       Inactive: text color textMuted, no border
│       Active: text primaryYellow, bottom bar 2px primaryYellow
│     TabBar indicator: none (custom pill underline only)
│
└── TAB CONTENT (scrollable list below)

```

#### State Handling
- **Empty query → Discovery mode**: Show trending topics grid (2-col masonry-style staggered heights)
- **Has query → Results mode**: Show filtered results by tab
- **Recent searches**: Shown as horizontal chip row above discovery when query is empty

#### Discovery Grid (empty query)
```
"TRENDING NOW" header with live pulse dot
2-column grid, items alternate between:
  - Small debate card (title + agree/disagree bar)
  - User suggestion card (avatar + username + follow button)
  - Topic pill cluster
Each card: neon glow border matching category color
Staggered animation: items slide-in with 60ms per-item delay
```

#### Search Results — Debate Card
```
Horizontal list item (not full card):
  Left: colored category dot (8px)
  Title: max 2 lines
  Right: agree% bar (compact 60px wide) + votes count
```

#### Search Results — People Card  
```
Row layout:
  Avatar (40px) with neon ring
  Name + @username (2 lines)
  Follow/Connect button (small outlined pill)
```

#### Animations
- Search bar focus: border color transitions to accentBlue with 200ms
- Results appear: ListView items slide from bottom with stagger
- Clear button: scales in from 0 when text is entered

---

### 2. NOTIFICATIONS SCREEN (`lib/screens/main/notifications_screen.dart`)

**Concept**: Activity feed — each notification type has its OWN visual identity

#### Layout
```
CustomScrollView
│
├── SliverAppBar (pinned, expandedHeight: 140)
│     Background: linear gradient accentBlue→accentTeal (topLeft→bottomRight)
│                 + diagonal scanline overlay
│     Title: "ACTIVITY" — h1, letterSpacing:3, white
│     Bottom: filter chips row (ALL | MENTIONS | VOTES | CONNECTIONS | SYSTEM)
│             horizontal scrollable, pill style
│             active chip: white bg + primaryBlack text
│             inactive: transparent + white/50 border
│     Actions: "Mark all read" icon (only if unread > 0)
│
└── SliverList
      Groups by date: "TODAY", "THIS WEEK", "EARLIER"
      Date header style: section header spec (left accent bar, ALL CAPS, textMuted)
```

#### Notification Tile Design (per type)
Each has a left-side colored vertical bar (3px, rounded) + icon container:

| Type | Bar Color | Icon | Icon Bg |
|------|-----------|------|---------|
| vote_agree | accentTeal | thumb_up | accentTeal/15 |
| vote_disagree | errorRed | thumb_down | errorRed/15 |
| comment | accentBlue | chat_bubble | accentBlue/15 |
| connection_request | primaryYellow | person_add | primaryYellow/15 |
| connection_accept | accentTeal | handshake | accentTeal/15 |
| debate_trending | accentOrange | trending_up | accentOrange/15 |
| system | textMuted | info | textMuted/15 |
| mention | primaryYellow | alternate_email | primaryYellow/15 |

```
Tile layout:
  │ [colored bar 3px] │ [icon container 44px] │ [text column] │ [time + dot] │
  
  Text column:
    Line 1: "<Actor>" (accentBlue, bold) + " " + action text (textPrimary)
    Line 2: context snippet (textMuted, 12px, maxLines:1, ellipsis)
  
  Unread dot: 8px circle, primaryYellow, Positioned right side
  Unread tile bg: primaryYellow/4 tint
  
  Read tile: no tint, no dot, bar color at 40% alpha
```

#### Animations
- New notifications: slide in from top with fade (when real-time arrives)
- Swipe to dismiss: slide left reveals red delete action
- Mark as read on tap: dot fades out + bg color transitions to transparent (300ms)
- "Mark all read" tapped: sequential dots fade with 30ms stagger

---

### 3. LEADERBOARD SCREEN (`lib/screens/main/leaderboard_screen.dart`)

**Concept**: Hall of fame — prestige aesthetic, competitive energy, podium-first layout

#### Layout
```
Background: darkBackground
            + radial gradient overlay: primaryYellow/8 from top-center

Column:
│
├── HEADER SECTION (custom, not AppBar)
│     paddingTop: SafeArea + 16
│     Left icon: emoji_events (primaryYellow, 32px) + "TOP DEBATERS" h2
│     Right: filter dropdown (compact, shows current period)
│
├── PERIOD TABS
│     3 pills: WEEKLY • MONTHLY • ALL TIME
│     Container: darkSurface bg, borderRadius 999
│     Active pill: primaryYellow bg, primaryBlack text, animated slide
│     Transition: AnimatedContainer 200ms
│
├── PODIUM (top 3 only — rank 1,2,3)
│     Custom podium widget:
│       Rank 2 (LEFT):  height 80px pedestal, accentBlue border avatar 52px
│       Rank 1 (CENTER): height 110px pedestal, crown icon above avatar, 
│                        primaryYellow neon ring 64px avatar, 
│                        primaryYellow glow boxShadow
│       Rank 3 (RIGHT): height 60px pedestal, accentOrange border avatar 52px
│     
│     Each podium block:
│       Pedestal: darkCardBg + colored top border (3px)
│       Avatar: CircleAvatar with colored ring
│       Username: below pedestal, bold
│       XP badge: small pill below username
│
├── RANK LIST (4th+)
│     ListView (remaining users)
│     Each row:
│       Left: rank number (#4, #5...) — textMuted, mono font
│       Avatar (40px) with subtle ring
│       Name + username
│       Right: XP pill (darkSurface bg + primaryYellow text)
│              + change indicator (▲3 accentTeal  / ▼2 errorRed / — textMuted)
│     
│     Divider: none (spacing only, 8px gap)
│     My rank: highlighted row (primaryYellow/5 bg + left border primaryYellow)
│
└── FOOTER: "Earn XP by debating, voting & commenting"
            (textMuted, italic, centered, 12px)
```

#### Animations
- Podium appears: each block slides up from bottom with 150ms stagger (rank 2 first, rank 1 last)  
- Crown on rank 1 bounces in: `ElasticOut` curve scale from 0
- XP change indicators: count-up animation from 0 to value on load
- Tab switch: list items fade out/in with crossfade 200ms

---

### 4. CREATE DEBATE SCREEN (`lib/screens/debate/create_debate_screen.dart`)

**Concept**: Studio mode — feels like you're launching something into the world

#### Layout
```
Scaffold:
  Background: darkBackground
  
  AppBar:
    transparent
    leading: X close button (textPrimary)
    title: "NEW DEBATE" — labelMedium, letterSpacing:3
    actions: post button → animated pill button
               default: "DRAFT" (outlined, textMuted)
               when title filled: "LAUNCH 🔥" (primaryYellow bg, primaryBlack)
               onPressed: _createDebate()
               Scale animation onPress

  Body: SingleChildScrollView
    padding: horizontal 20, top 16
    
    ── STEP INDICATOR ──
    3 steps: TOPIC • DETAILS • SETTINGS
    Progress bar (thin, 4px, accentTeal fill, darkSurface bg)
    Current step label below
    
    ── STEP 1: TOPIC ──
    Section label: "WHAT'S THE DEBATE?" (section header style)
    
    Title field:
      NO standard TextField decoration
      Custom: just a thick bottom border (2px accentBlue when focused, darkBorder when not)
      fontSize: 22px, bold, textPrimary
      hint: "Is [X] better than [Y]?" — creative hint
      maxLength: 140 (shown as count top-right: "72/140" in textMuted)
      counter badge: changes to errorRed when < 20 chars remaining
    
    SizedBox(20)
    
    Description field:
      Same borderStyle as title
      fontSize: 15px, textSecondary, height:1.6
      hint: "Add context, rules, or background info..."
      maxLines: 4
      maxLength: 500
    
    ── STEP 2: DETAILS ──
    Section label: "CATEGORY & SETTINGS"
    
    Category selector:
      Horizontal scrollable chip row
      Each chip: pill shape, category icon + name
      Selected: primaryYellow bg + primaryBlack text + scale 1.05
      Unselected: darkSurface + darkBorder + textMuted
      Animation: smooth color transition 150ms
    
    Debate type toggle (text only / image / video):
      Segmented control style, icons only
      Selected: darkBorder with neon color icon
    
    Media upload area (shows only if image/video selected):
      Dashed border container (2px, dashed, darkBorder)
      Center: upload icon + "Tap to add media" text
      After upload: preview thumbnail fills container
    
    ── STEP 3: SETTINGS (collapsible) ──
    Duration picker: "Debate ends in X days" — stepper +/- buttons
    Visibility: Public / Followers only — toggle pills
    Allow comments: Switch (accentTeal active color)
```

#### Animations
- Title character count: smooth count transition
- Category chip select: spring scale + color crossfade
- Step progress bar: animated fill with easeOut
- Launch button: scale pulse when eligible

---

### 5. CHAT DETAIL SCREEN (`lib/screens/main/chat_detail_screen.dart`)

**Concept**: Room chat — community space, not private DM (feels public and bold)

#### Layout
```
Scaffold:
  backgroundColor: darkBackground
  
  AppBar:
    backgroundColor: darkCardBg
    border: bottom 1px darkBorder
    
    leading: back button
    
    title: Row(
      Avatar (32px, room icon or initial)
      Column:
        room name (labelLarge, primaryYellow)
        "${memberCount} members online" (11px, accentTeal — 'online' is always shown for energy)
    )
    
    actions: 
      search icon (textPrimary)
      more_vert showing: [Members, Room Info, Leave Room, Report]
  
  Body: Column
    │
    ├── MEMBERS ONLINE BAR (horizontal scroll, subtle)
    │     Height: 56px
    │     Background: darkSurface, bottom border darkBorder
    │     "ONLINE" label (9px, accentTeal, letterSpacing:2)
    │     Horizontal ListView of small avatars (28px)
    │       Each with accentTeal online dot bottom-right
    │     Max show 8, then "+N" circle
    │
    ├── MESSAGES LIST (Expanded)
    │     Reversed = true (latest at bottom)
    │     padding: horizontal 16, vertical 8
    │     
    │     Message bubble:
    │       OWN messages (right aligned):
    │         bg: primaryYellow/15 with primaryYellow/30 border (1px)
    │         borderRadius: 18, 18, 4, 18 (bottom-right squared)
    │         text: textPrimary
    │       
    │       OTHER messages (left aligned):
    │         bg: darkCardBg with darkBorder (1px)  
    │         borderRadius: 18, 18, 18, 4
    │         text: textPrimary
    │         Above bubble: username (9px, colored — cycle through accentBlue/accentTeal/primaryYellow/accentOrange by hash)
    │       
    │       Timestamp: 10px, textMuted, shown only on last message of consecutive group
    │       
    │       System messages (centered):
    │         italic, textMuted, 11px, no bubble
    │     
    │     Empty state: 
    │       Center column: room icon (64px, darkBorder color) + "Start the discussion" 
    │
    ├── TYPING INDICATOR
    │     AnimatedSwitcher — slide up when someone is typing
    │     "3 members typing..." with animated dots (3 dots bouncing in sequence)
    │
    └── INPUT BAR
          BackdropFilter: blur sigmaX:20, sigmaY:20
          background: darkCardBg/80
          border top: 1px darkBorder
          padding: 12 horizontal, 8 vertical, + viewInsets.bottom
          
          Row:
            emoji button (textMuted icon)
            VerzTextField (flex:1, no label, hint "Message the room...")
            send button: 44px circle
              inactive: darkSurface, icon textMuted
              active (has text): accentTeal bg, icon primaryBlack, glow shadow
              animate: AnimatedContainer 200ms
```

#### Animations
- Messages appear: slide up + fade from bottom, 200ms easeOut
- Send button activates: AnimatedContainer color change with scale spring
- New message from others: subtle accent flash on bubble (opacity 0.4→0 over 800ms)

---

### 6. DIRECT MESSAGE SCREEN (`lib/screens/messages/direct_message_screen.dart`)

**Concept**: Intimate, sleek, frosted-glass chat — WhatsApp × Discord energy

#### Layout
```
Scaffold:
  backgroundColor: darkBackground
  
  AppBar:
    backgroundColor: transparent (use stack with blurred bg instead for cool effect)
    
    Use a PreferredSize with custom widget:
      Container with BackdropFilter + darkCardBg/80
      height: 64 + safeArea.top
      
      Row inside:
        back arrow
        Avatar (36px) with last-active dot (accentTeal if online, textMuted if offline)
        Column:
          displayName (labelLarge, textPrimary)
          last active status OR "typing..." (animated, textMuted/accentTeal, 11px)
        Spacer
        video_call icon (textMuted) — disabled but shows intent  
        phone icon (textMuted) — disabled
        more_vert → [View Profile, Block, Report]
  
  Body: Column
    │
    ├── CONNECTION NOTICE BANNER (shows if !_canMessage)
    │     Amber/yellow notification strip at top
    │     "Connect to send messages"
    │     AnimatedSwitcher: slides in from top when !_canMessage
    │
    ├── MESSAGES LIST (Expanded, reversed)
    │     
    │     Group messages by sender in consecutive runs
    │     Show date separator: "Today", "Yesterday", "March 12"
    │       Separator style: thin line darkBorder + date pill (darkSurface bg, textMuted, 11px)
    │     
    │     Own message bubble:
    │       bg: accentBlue/15 with accentBlue/25 border
    │       BorderRadius: 20, 4, 20, 20
    │       Status icon bottom-right: 
    │         sending → animated spinner 8px
    │         sent    → single check (textMuted)
    │         read    → double check (accentBlue)
    │         failed  → retry icon (errorRed) — tappable, shows retry option
    │       
    │     Other bubble:
    │       bg: darkCardBg, border: 1px darkBorder
    │       BorderRadius: 4, 20, 20, 20
    │     
    │     Image/media messages:
    │       Rounded preview (borderRadius:12), max height 220px
    │       Tap to full-screen
    │     
    │     Long press on message → action sheet:
    │       React (6 emojis row: 👍💬❤️🔥🤯😂)
    │       Copy, Reply, Report, Delete (own only)
    │
    ├── REPLY PREVIEW BAR (AnimatedSwitcher, shows when replying)
    │     Slide up from bottom of message list
    │     Left: accent vertical bar (3px, accentBlue)
    │     "Replying to @username" (accentBlue, 11px)
    │     Quoted message snippet (textMuted, 12px, 1 line)
    │     Right: X to cancel reply
    │
    └── INPUT BAR  
          Same frosted-glass style as chat_detail
          
          Row:
            attach icon (textMuted)
            VerzTextField (flex:1, hint "Message @username...")
            
            AnimatedSwitcher on right side:
              if text empty: mic icon (textMuted) — no function needed
              if text present: send button
                accentTeal bg + primaryBlack icon + glow
                SpringPhysicsAnimation on press
```

#### Animations
- Typing indicator: 3 dots animate (bounce stagger 150ms between each)
- Message status icons: fade transition between states
- Reply bar: slide up with CurvedAnimation easeOut 250ms
- Failed message: errorRed pulse animation (fade 0.6→0.3→0.6, loop until retry)
- Reaction sheet: scale + fade in from message position

---

### 7. CONNECTIONS SCREEN (`lib/screens/connections/connections_list_screen.dart`)

**Concept**: Your network map — feels like you're building something

#### Layout
```
Scaffold:
  backgroundColor: darkBackground
  
  CustomScrollView:
    │
    ├── SliverAppBar (pinned, expandedHeight:160)
    │     Background: gradient accentTeal→accentBlue
    │                 + scanline overlay
    │     Title toolbar: "NETWORK" — h1, letterSpacing:3
    │     Actions: pending requests badge icon (primaryYellow + count)
    │     
    │     FlexibleSpaceBar:
    │       Stats row in expanded area:
    │         3 pills — "X Connected" (accentTeal) | "X Following" (accentBlue) | "X Followers" (primaryYellow)
    │         Each pill: darkCardBg/50 bg, white text, bold number
    │
    ├── SliverPersistentHeader (sticky TabBar + Search)
    │     4 tabs: CONNECTED • FOLLOWING • FOLLOWERS • DISCOVER
    │     Below tabs: search field (same glass style as search screen)
    │
    └── SliverList (user grid)
          2-column grid layout (NOR ListView — use SliverGrid)
          
          Each user card:
            darkCardBg bg
            borderRadius: 16
            border: 1px darkBorder
            
            Top section:
              User avatar (56px, neon ring, full width gradient strip behind)
              Online dot (accentTeal, 10px)
            
            Bottom section (padding:12):
              displayName (labelMedium, bold)
              @username (bodySmall, textMuted)
              
              Row:
                Debate count pill (accentBlue/15, accentBlue text, "N debates")
              
              Full-width action button:
                Connected   → "CONNECTED ✓" (darkSurface bg, textMuted)
                Following   → "FOLLOWING" (accentBlue/20 bg, accentBlue)
                Pending out → "PENDING..." 
                Pending in  → "ACCEPT" (accentTeal) + "DECLINE" (outlined) — side by side
                None        → "FOLLOW" (primaryYellow) + "CONNECT" icon button
```

#### Animations
- Grid items: staggered scale-in from 0.8→1.0 with opacity
- Follow action: immediate optimistic button state change + ripple
- Stats pills: count-up animation from 0 on load

---

### 8. PENDING CONNECTIONS SCREEN (`lib/screens/connections/pending_connections_screen.dart`)

**Concept**: Decision queue — clear, action-forward

#### Layout
```
AppBar: "PENDING REQUESTS" — standard back button
        Subtitle: "X requests waiting"

Body: ListView
  Two sections:
  
  RECEIVED (people who sent you a request):
    Section header with count badge
    Each card:
      Row layout: avatar (48px) + name/@username + time sent
      Right: 2 action buttons
        "ACCEPT" — accentTeal pill
        "DECLINE" — outlined errorRed pill
      Swipe right gesture also = accept
      Swipe left gesture also = decline
      
  SENT (requests you sent, pending response):
    Section header with count
    Each card:
      Row: avatar + name + "Waiting for response" (italic, textMuted)
      Right: "WITHDRAW" text button (errorRed/70 color)
```

---

### 9. SETTINGS SCREEN (`lib/screens/settings/settings_screen.dart`)

**Concept**: Control center — looks like a premium app settings panel

#### Layout
```
Scaffold:
  backgroundColor: darkBackground
  
  AppBar:
    transparent, back button
    title: "SETTINGS" — labelMedium, letterSpacing:3
  
  User profile card at top:
    Horizontal card: avatar (52px) + name + @username + "Edit Profile" pill button
    Card: darkCardBg, border darkBorder, borderRadius:16
    Margin: 16 all sides
  
  ListView of settings groups:
  
  Each group = Card with:
    darkCardBg bg, borderRadius:16, border: 1px darkBorder
    Margin bottom: 12
    
  PRIVACY GROUP:
    Header: 🔒 PRIVACY (section header style)
    ├── Private Account toggle (accentTeal active, description below)
    └── Messaging Privacy (dropdown/tile → bottom sheet selector)
  
  NOTIFICATIONS GROUP:
    Header: 🔔 NOTIFICATIONS
    ├── Debate updates toggle
    ├── Connection requests toggle
    └── Messages toggle
  
  APPEARANCE GROUP:
    Header: 🎨 APPEARANCE
    └── Dark Mode: locked "DARK MODE ONLY" badge (primaryYellow pill, not tappable)
  
  ACCOUNT GROUP:
    Header: 👤 ACCOUNT
    ├── Change Password
    ├── Connected accounts (OAuth)
    └── Delete Account (errorRed text)
  
  SUPPORT GROUP:
    Header: 💬 SUPPORT
    ├── Help Center
    ├── Report a Bug
    └── Privacy Policy / Terms
  
  SIGN OUT BUTTON:
    Full-width outlined button
    border: errorRed
    text: "SIGN OUT" — errorRed
    icon: logout_rounded
    Confirmation bottom sheet before signing out
```

---

### 10. ROOM MEMBERS SCREEN (`lib/screens/rooms/room_members_screen.dart`)

**Concept**: Clear list of who's in the community

#### Layout
```
AppBar: "MEMBERS" — with back button
        Subtitle: room name

Search bar (top, always visible)

ListView:
  Grouped by role: ADMINS first, then MEMBERS
  Section headers (standard style)
  
  Each member tile:
    Avatar (44px) + displayName + @username
    Right: role badge (ADMIN: primaryYellow pill | MEMBER: textMuted text)
    On tap: push to profile screen
```

---

## WIDGET REDESIGNS

### `lib/widgets/debate/debate_card.dart`
If this standalone widget exists, ensure it matches the card spec from home_screen.
The card in home_screen._DebateCard is the reference — keep it consistent.

### Loading Shimmer Widget
Create `lib/widgets/common/shimmer_loader.dart`:
```dart
// Animated shimmer that replaces loading spinners for lists
// Uses AnimationController with CurvedAnimation
// Gradient: darkSurface → darkBorder → darkSurface (horizontal sweep)
// Apply to: any list that loads data (debates, users, notifications)
// Use Container with ShaderMask wrapping a placeholder structure
```

### Neon Glow Button (`lib/widgets/common/verz_button.dart`)
Ensure this supports a `glowColor` param that adds BoxShadow:
```dart
BoxShadow(color: glowColor.withAlpha(0.4), blurRadius:16, spreadRadius:0)
```
Active press state: wrap in `GestureDetector` with `onTapDown`/`onTapUp` to animate `Transform.scale(0.94)`.

---

## ANIMATION COMPONENTS CHECKLIST

Create or ensure these exist:

### `lib/widgets/common/animated_list_item.dart`
```dart
// Wraps any widget with staggered slide+fade entry animation
// Parameters: index (for stagger delay), child, direction (Axis)
// Delay = index * 40ms, duration = 280ms, curve: Curves.easeOut
```

### `lib/widgets/common/neon_pulse.dart`
```dart
// Wraps icon/dot with looping glow pulse
// AnimationController: 2s, repeat(reverse:true)
// Tween<double>(0.2, 0.6) on boxShadow alpha
// Parameters: color, child, radius
```

### `lib/widgets/common/skeleton_card.dart`
```dart
// Shimmer placeholder card
// Matches rough layout of debate_card
// Used while isLoading && debates.isEmpty
```

---

## HOME SHELL UTILITY DRAWER RESTYLE

The drawer already exists — restyle per these specs:

```
Drawer:
  width: MediaQuery.size.width * 0.82
  background: Stack(
    darkBackground,
    Positioned left: Container(width:3, gradient: vertical accentTeal→primaryYellow)
  )
  
  Top section: user avatar + name (from authProvider)
  
  Menu items (with icons):
    🏠 Feed              → /home
    🔍 Search            → /search  
    👥 Communities       → /rooms
    🏆 Leaderboard       → /leaderboard
    🔗 Connections       → /connections
    🔔 Notifications     → /notifications (+ badge)
    ⚙️ Settings          → /settings
  
  Active item: primaryYellow icon + text, darkCardBg row bg
  Inactive: textMuted icon, transparent bg
  
  Bottom section: app version + copyright
```

---

## ROUTING ADDITIONS

Ensure `app_router.dart` has these routes (add if missing):
- `/leaderboard` → LeaderboardScreen
- `/connections` → ConnectionsListScreen  
- `/connections/pending` → PendingConnectionsScreen
- `/profile/:userId` → ProfileScreen(userId: state.pathParameters['userId'])
- `/search` → SearchScreen (also accessible via shell tab)

---

## IMPLEMENTATION RULES

1. **No `isDark` conditionals** — app is dark-only; hardcode dark tokens
2. **No `Colors.white` or `Colors.black`** directly — use `AppColors.darkText` / `AppColors.primaryBlack`
3. **No standard `BottomNavigationBar`** — custom nav bar only
4. **No `AppColors.primary`** for main accent — use `AppColors.primaryYellow` explicitly
5. **No `AppColors.surface`** — use `AppColors.darkSurface` or `AppColors.darkCardBg`
6. **Every screen must have** at least one animation (entry, loading shimmer, or micro-interaction)
7. **All new CircularProgressIndicator** must use a brand color
   - Loading lists: `accentTeal`
   - Auth actions: `primaryYellow`  
   - Chat sending: `accentBlue`
8. **All SnackBars**: `backgroundColor: AppColors.darkCardBg`, `behavior: SnackBarBehavior.floating`, `shape: StadiumBorder`
9. **All AlertDialogs / bottom sheets**: `backgroundColor: AppColors.darkCardBg`, top handle bar (40×4px, darkBorder, radius 999)
10. **All empty states must have**: large icon (56px, 25% brand color opacity) + title + subtitle + action button

---

## PRIORITY ORDER FOR IMPLEMENTATION

Implement in this order (highest visual impact first):
1. Navigation bar (home_shell.dart) — FIRST, affects all screens
2. Create Debate screen — users arrive here via prominent Create button
3. Direct Message screen — most complex, highest engagement
4. Chat Detail (room chat) screen
5. Notifications screen
6. Leaderboard screen
7. Search screen
8. Connections + Pending screens
9. Settings screen
10. Room Members screen
11. Shimmer/animation widgets

---

## VALIDATION CHECKLIST (run after each screen)

- [ ] No analyzer errors (`flutter analyze lib/`)
- [ ] No `isDark` conditionals
- [ ] No `AppColors.primary` (use `AppColors.primaryYellow`)
- [ ] No `AppColors.surface` (use `AppColors.darkSurface`)
- [ ] No `Colors.white` or `Colors.black` raw
- [ ] Entry animation present
- [ ] Empty state complete (icon + title + subtitle + action)
- [ ] Loading state complete (shimmer or spinner with brand color)
- [ ] Error state complete (icon + message + retry button)
- [ ] All tappable areas: minimum 44×44 touch target
- [ ] Bottom safe area respected (MediaQuery.padding.bottom)

---

## FINAL BUILD VALIDATION

After all screens implemented:
```
flutter analyze lib/        # must output: No issues found!
flutter build apk --debug   # must output: √ Built
```

Every screen must be reachable from the navigation (no orphan screens).
Every button must have an `onPressed` (no null for intended actions).
