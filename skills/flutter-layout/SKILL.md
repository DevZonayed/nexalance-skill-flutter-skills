---
name: "flutter-layout"
description: "How to build your app's layout using Flutter's layout widgets and constraint system"
metadata:
  urls:
    - "https://docs.flutter.dev/ui/layout"
    - "https://docs.flutter.dev/ui/layout/tutorial"
    - "https://docs.flutter.dev/get-started/fundamentals/layout"
    - "https://docs.flutter.dev/ui/design/material"
    - "https://docs.flutter.dev/learn/tutorial/layout"
    - "https://docs.flutter.dev/ui/adaptive-responsive"
    - "https://docs.flutter.dev/learn/tutorial/adaptive-layout"
    - "https://docs.flutter.dev/ui/layout/constraints"
    - "https://docs.flutter.dev/ui/widgets/layout"
    - "https://docs.flutter.dev/learn/pathway/tutorial/layout"
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Fri, 27 Feb 2026 00:12:57 GMT"

---
# flutter-layout-architect

## Goal
Translates UI/UX requirements into structured, efficient, and responsive Flutter widget trees. Constructs layouts using Flutter's constraint model (constraints go down, sizes go up, parent sets position) to prevent overflow errors and ensure pixel-perfect rendering across varying screen sizes. Implements adaptive breakpoints using `LayoutBuilder` and handles complex scrolling behaviors.

## Instructions

1. **Analyze UI Requirements & Determine Layout Strategy**
   Evaluate the target UI and break it down into logical widget groupings. Use the following Decision Logic to select the appropriate layout primitives:
   
   *Decision Logic: Layout Selection*
   *   **If** the UI requires elements arranged linearly:
       *   *Horizontal:* Use `Row`.
       *   *Vertical:* Use `Column`.
       *   *Action:* Wrap children in `Expanded` or `Flexible` to manage remaining space and prevent overflow.
   *   **If** elements must overlap (e.g., text over an image):
       *   *Action:* Use `Stack` with `Positioned` or `Align` widgets.
   *   **If** the content exceeds the screen size or requires repeating elements:
       *   *Linear:* Use `ListView` or `ListView.builder`.
       *   *2D Array:* Use `GridView` or `GridView.builder`.
   *   **If** the UI must adapt to different screen sizes (e.g., mobile vs. tablet):
       *   *Action:* Use `LayoutBuilder` to read constraints and branch the widget tree.
   *   **If** a single widget needs specific sizing, padding, or decoration:
       *   *Action:* Use `Container`, `SizedBox`, or `Padding`.

2. **Confirm Widget Tree Architecture**
   **STOP AND ASK THE USER:** Present a high-level bulleted outline of the proposed widget tree. Ask the user to confirm the structure or provide specific dimensions/padding requirements before generating the full implementation.

3. **Implement Core Layouts**
   Construct the layout using strict compositional patterns. 
   
   *Example: Responsive Row/Column Composition*
   ```dart
   Widget buildResponsiveRow(BuildContext context) {
     return Padding(
       padding: const EdgeInsets.all(16.0),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Expanded(
             flex: 2,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: const [
                 Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                 SizedBox(height: 8),
                 Text('Subtitle description that might wrap to multiple lines.'),
               ],
             ),
           ),
           const SizedBox(width: 16),
           const Icon(Icons.star, color: Colors.red),
         ],
       ),
     );
   }
   ```

4. **Implement Adaptive Breakpoints**
   When building for multiple form factors, use `LayoutBuilder` to branch logic based on available constraints, rather than relying solely on screen size.

   *Example: Adaptive LayoutBuilder*
   ```dart
   Widget buildAdaptiveLayout(BuildContext context) {
     return LayoutBuilder(
       builder: (BuildContext context, BoxConstraints constraints) {
         if (constraints.maxWidth > 600) {
           return Row(
             children: [
               const SizedBox(width: 250, child: SidebarWidget()),
               const VerticalDivider(width: 1),
               Expanded(child: MainContentWidget()),
             ],
           );
         } else {
           return const MainContentWidget(); // Sidebar moved to a Drawer
         }
       },
     );
   }
   ```

5. **Enforce Constraint Rules**
   Apply the rule: *Constraints go down. Sizes go up. Parent sets position.* 
   *   Never place a `ListView` directly inside a `Column` without wrapping it in an `Expanded` or `Flexible` widget.
   *   Use `ConstrainedBox` to enforce minimum or maximum dimensions on child widgets that attempt to size themselves infinitely.

   *Example: Bounding Infinite Constraints*
   ```dart
   Widget buildBoundedList() {
     return Column(
       children: [
         const Text('Header'),
         Expanded( // Prevents unbounded height error from ListView
           child: ListView.builder(
             itemCount: 50,
             itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
           ),
         ),
       ],
     );
   }
   ```

6. **Validate and Fix (Feedback Loop)**
   Review the generated layout code for common constraint violations.
   *   *Check:* Are there `Row` or `Column` widgets containing text that might overflow? 
   *   *Fix:* Wrap the `Text` in an `Expanded` or `Flexible` widget.
   *   *Check:* Is a `Container` with `double.infinity` placed inside an `UnconstrainedBox` or `Row`?
   *   *Fix:* Replace `double.infinity` with a bounded constraint or use `Expanded`.

## Constraints
*   Do not use external packages for basic layouts unless explicitly requested; rely on standard Flutter widgets (`Row`, `Column`, `Stack`, `ListView`, `LayoutBuilder`).
*   Do not wrap the final output in markdown code blocks (e.g., ` ```markdown `).
*   Never use `double.infinity` inside a scrollable widget (like `ListView` or `SingleChildScrollView`) without a bounding parent.
*   Always use `const` constructors for widgets where the state and properties do not change.
*   Do not include URLs or external links in the generated code or explanations.
