# Landing-page animation assets

The animation is rendered by [AnimatedBackground.jsx](../../src/components/common/jsx/AnimatedBackground.jsx) and styled by [AnimatedBackground.css](../../src/components/common/css/AnimatedBackground.css). Images are served from this directory using `/images/<filename>` URLs.

| File | CSS animation slot | Use |
|---|---|---|
| `map.png` | `animated-map` | Map illustration |
| `passport.png` | `animated-letsgo` | Travel-document illustration |
| `man.png` | `animated-bagman` | Traveler character |
| `plane.png` | `animated-plane` | Airplane illustration |
| `travel_man.png` | `animated-tourist` | Traveler character |
| `confuse_man.png` | `animated-confuse` | Confused traveler |
| `search.png` | `animated-content` | Search illustration |
| `trip_plan.png` | `animated-happy` | Trip-planning illustration |
| `happy.png` | `animated-student` | Celebration illustration |

Some CSS slot names come from an earlier animation design and differ from the artwork now assigned to them. The current JSX image paths are authoritative.

The sprite sequence uses `--animation-cycle: 24s`. Individual visibility, motion and responsive sizing are defined in the CSS keyframes; the brand text comes from `GlobalConfig.APP_NAME`.

When replacing artwork, keep the filename or update the JSX `src`, check the slot's size and keyframes, and verify the landing page at desktop and mobile widths. Keep source/license evidence with any replacement asset; this file does not establish ownership or a license for the existing PNGs.
