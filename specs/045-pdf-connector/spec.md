# Feature Specification: PDF Connector

**Feature Branch**: `045-pdf-connector`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a PDF connector that captures PDF reading activity and links document content to events"

## User Scenarios & Testing

### User Story 1 - PDF Open and Reading Detection (Priority: P1)

When the user opens a PDF in a PDF viewer (Adobe Acrobat, browser PDF viewer, or system PDF viewer), the connector detects the open and captures: file path, title, author, page count, and the current page. As the user reads and scrolls through pages, progress events are published.

**Why this priority**: PDFs are a primary format for research papers, documentation, and reports. Tracking PDF reading provides rich context about learning activity.

**Independent Test**: Open a PDF in the default system PDF viewer. Verify an event appears: "Opened PDF: Attention Is All You Need (15 pages)" with type "pdf.opened", source "pdf-viewer", and metadata including author and page count. Scroll to page 5, verify a "pdf.page" event appears: "Page 5/15".

**Acceptance Scenarios**:

1. **Given** a PDF is opened, **When** the connector detects the file open, **Then** a "pdf.opened" event is published with file name, path, title (from metadata), author, page count, and source viewer within 10 seconds
2. **Given** the user navigates to a different page, **When** the page changes, **Then** a "pdf.page" event is published with the new page number and total pages

---

### User Story 2 - PDF Content Extraction (Priority: P2)

The connector extracts text content from PDFs for indexing and search. Extraction happens in the background (async) and publishes the extracted content as a separate event linked to the PDF open event. The knowledge engine indexes the extracted text for full-text search.

**Why this priority**: Full-text indexing of PDFs makes their content searchable alongside other events. Users can find "that paper about transformers" without remembering the file name.

**Independent Test**: Open a PDF with text content. After 30 seconds (allowing for extraction), search for a keyword from the PDF in the OSAI Chat Bar. Verify the PDF appears in search results with the matching text highlighted.

**Acceptance Scenarios**:

1. **Given** a PDF with text content is opened, **When** the extraction completes, **Then** a "pdf.content_extracted" event is published linked to the original open event, with extracted text (page-by-page) and word count
2. **Given** extracted PDF content, **When** the user searches for a phrase from the PDF, **Then** the PDF appears in search results with the excerpt showing the matching text in context

---

### User Story 3 - PDF Annotations and Highlights (Priority: P3)

When the user annotates or highlights a PDF, the connector captures these actions. Events include: highlight added (page, selected text), note added (page, content), and bookmark added (page). These annotations are linked to the PDF document for later reference.

**Why this priority**: Annotations represent active engagement with content. They're more valuable than passive page views for understanding what the user found important.

**Independent Test**: Open a PDF, highlight a sentence, and add a note. Verify events: "Highlighted: 'Attention is all you need' on page 3 (PDF: Attention Is All You Need)" and "Added note on page 3: 'Key insight about attention mechanisms'".

**Acceptance Scenarios**:

1. **Given** a PDF is open with annotations, **When** the user highlights text, **Then** a "pdf.highlight" event is published with page number, highlighted text, and a link to the parent PDF event
2. **Given** a PDF is open, **When** the user adds a note, **Then** a "pdf.note" event is published with page number and note content

---

### User Story 4 - PDF Viewer Integration (Priority: P2)

The connector supports multiple PDF viewers: system default, browser-based (Chrome/Firefox built-in), Adobe Acrobat, and third-party viewers (SumatraPDF, Foxit, Okular). Detection uses window title monitoring, file system watching (recent files), and optional viewer plugins.

**Why this priority**: Users have diverse PDF viewer preferences. Broad support ensures maximum coverage.

**Independent Test**: Open PDFs in Chrome's built-in viewer (drag to browser), Adobe Acrobat, and SumatraPDF. Verify all three produce "pdf.opened" events with correct source identification.

**Acceptance Scenarios**:

1. **Given** Chrome's built-in PDF viewer, **When** a PDF is opened, **Then** the connector detects it via window title and published a "pdf.opened" event with source "chrome-pdf-viewer"
2. **Given** Adobe Acrobat, **When** a PDF is opened, **Then** an event is published with source "adobe-acrobat" and includes additional metadata (bookmarks, document info)

---

### Edge Cases

- What happens when the PDF is password-protected?
- How are scanned PDFs (image-only, no text) handled?
- What happens when a PDF is opened from a web page vs. local file?
- How are very large PDFs (1000+ pages) handled?
- What happens when the user opens multiple PDFs simultaneously?
- How is PDF content privacy handled (sensitive documents)?

## Requirements

### Functional Requirements

- **FR-001**: Connector MUST detect PDF file opens and publish "pdf.opened" events
- **FR-002**: "pdf.opened" events MUST include: file path, title, author, page count, source viewer
- **FR-003**: Connector MUST detect page navigation and publish "pdf.page" events with page number
- **FR-004**: Connector MUST extract text content from PDFs for full-text indexing
- **FR-005**: Extracted content MUST be published as linked events for indexing
- **FR-006**: Connector MUST capture highlights: page, selected text, color (if available)
- **FR-007**: Connector MUST capture notes: page, content, timestamp
- **FR-008**: Connector MUST support multiple PDF viewers via window title detection + file watcher integration (see per-tool table below)
- **FR-009**: Connector MUST handle password-protected PDFs gracefully (no content extraction)
- **FR-010**: Connector MUST handle scanned/image-only PDFs (OCR-extracted text if possible)
- **FR-011**: Page change events MUST be throttled to at most once per 5 seconds
- **FR-012**: Connector MUST accept control signals (`enable`, `disable`, `pause`, `resume`) from the Rust core via IPC — see spec 063. On `disable`, stop all PDF detection and drop timers. On `pause`, stop publishing but keep accessibility polling active. On `resume`, resume publishing.
- **FR-013**: Connector MUST send a heartbeat to the Rust core every 60 seconds via IPC, containing `events_today`, `last_event_at`, `pdfs_open`, and any errors — see spec 063 FR-027
- **FR-014**: Connector MUST register a `config_schema` listing its tool-specific settings (OCR toggle, excluded directories) as configurables — see spec 063 FR-014

### Per-Tool Connector Specifications

| Tool | App ID | How it's detected | How page changes are tracked | Setup |
|------|--------|-------------------|------------------------------|-------|
| **Adobe Acrobat** | `com.adobe.acrobat` | Window title pattern: `"* - Adobe Acrobat*"` or `"* - Adobe Acrobat Reader*"`. File path obtained via accessibility API or `GetWindowText` + file watcher cross-reference. | Accessibility API (Windows: `IAccessible`, macOS: `NSAccessibility`) — query current page number from the page navigation control. Poll every 5 seconds. | No user setup needed. macOS requires Accessibility permission grant. |
| **SumatraPDF** | `com.sumatrapdf` | Window title pattern: `"* - SumatraPDF"`. File path from title (SumatraPDF shows filename in title bar). | SumatraPDF has a `--cmd` option for IPC, but simpler: poll window title for page indicator pattern `"Page X/Y"` every 5 seconds. | No setup needed. Portable, open-source. |
| **Okular** | `org.kde.okular` | Window title pattern: `"*.pdf - Okular"` (Linux, KDE). File path from title. | Okular exposes D-Bus interface (`org.kde.okular`). Query current page via `pageNumber()` method. | No setup on KDE. On other DEs, D-Bus may require `kdelibs`. Fallback: window title polling. |
| **Zathura** | `org.zathura` | Window title pattern: `"* - zathura*"`. File path from title. | Zathura exposes a Unix socket IPC (like mpv): `--synctex` or check for `zathura-ipc`. Send `{"command": "page"}` via socket. | No setup needed. Open-source. |
| **Browser (Chrome PDF)** | `com.google.Chrome` | Handled by the browser extension (spec 006). Extension detects `chrome-extension://mhjfbmdgcfjbbpaeojofohoefgiehjai` PDF viewer URL. | Chrome's extension API provides `webNavigation` + content script injection. The extension injects a script that polls `document.querySelector("#pageNumber").value`. | Already handled by the browser extension — no separate setup. |
| **Browser (Firefox PDF)** | `com.mozilla.firefox` | Same as Chrome — handled by Firefox extension. Firefox uses `resource://pdf.js/web/viewer.html`. | Same approach: extension content script reads PDF viewer page input element. | Already handled by Firefox extension. |
| **System default** | `os.system-pdf-viewer` | When a PDF is opened via the file watcher (spec 008) — `file.opened` event with `.pdf` extension. No viewer-specific tracking. | No page tracking — the connector only knows the file was opened. Content extraction still runs. | No setup needed. |

**Content extraction** (for all tools): When `file.opened` / `pdf.opened` is detected, the connector schedules async text extraction using `pdf.js` (Mozilla's OSS PDF parser, ~1.5 MB, runs in Node.js). The extracted text is published as a `pdf.content_extracted` event linked to the PDF open event, which the knowledge engine indexes for full-text search. OCR (Tesseract.js) is optional and user-configurable.

### Key Entities

- **PDFDocument**: A PDF document. Attributes: id, filePath, title, author, pageCount, fileHash (for deduplication), openedAt, lastPageAt, totalReadingTime.
- **PDFPageEvent**: A page view event. Attributes: documentId, pageNumber, totalPages, viewDuration, timestamp.
- **PDFAnnotation**: An annotation on a PDF. Attributes: id, documentId, type (highlight/note/bookmark), page, content (highlighted text or note text), color, createdAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: PDF open detection latency: < 10 seconds from file open
- **SC-002**: Page change detection latency: < 3 seconds
- **SC-003**: Text extraction for a 50-page PDF completes in under 30 seconds
- **SC-004**: OCR extraction for scanned PDFs (if available) completes within 2 minutes per 50 pages
- **SC-005**: Annotation capture latency: < 5 seconds from user action

## Assumptions

- Primary detection via OS-level window title monitoring + file system watchers
- Text extraction uses `pdf.js` or `pdf-extract` library
- OCR support uses Tesseract.js (optional, resource-intensive)
- Browser PDF viewing detected via browser extension integration (spec 006)
- PDF viewer detection via window title pattern matching
- File watching via the existing file watcher service (spec 008)
- Password-protected PDFs: detected but not extracted
- Privacy: users can configure which directories/files to exclude
- Communication with the Rust core uses the named pipe (Windows) or Unix socket — the same SDK connection as other connectors (see protocol §7 for IPC transport detail)
- Source code lives at `connectors/pdf/` in the monorepo