# Excel to Salesforce

An Excel add-in that adds a **Salesforce Tools** tab to the ribbon. You sign in to your org, list Opportunities in a sheet, and press **Create Quote**. One API call creates a Quote for every row, and the new Quote IDs are written back into the sheet.

> 📄 **Case study:** [https://YOUR-PORTFOLIO-URL/work/excel-to-salesforce](https://YOUR-PORTFOLIO-URL/work/excel-to-salesforce) · More of my work at **[https://YOUR-PORTFOLIO-URL](https://YOUR-PORTFOLIO-URL)**

```
Excel ribbon (VBA)  ──POST /services/apexrest/createQuotes──▶  Apex REST class  ──▶  one bulk insert of Quote__c
        ▲                                                            │
        └──────────────── 201 { "ids": "a01…,a02…" } ◀───────────────┘
```

## Why

Sales ops teams often keep Opportunity lists in Excel and then create each Quote in Salesforce by hand, one record at a time. This add-in turns that into one button press and one API round trip.

## How it works

| Piece | File | What it does |
| --- | --- | --- |
| Ribbon UI | [`customUI.xlm`](customUI.xlm) | Office RibbonX XML. Adds a *Salesforce Tools* tab with a **Login / Logout** button and a **Create Quote** button. |
| VBA module | [`Code.xlam`](Code.xlam) | Plain-text export of the macros, so you can read the code on GitHub. Handles login, logout, building the JSON payload and calling the Apex endpoint. |
| Packaged add-in | [`Book 4.xlam`](Book%204.xlam) | The add-in you load in Excel. It contains the ribbon and the VBA. |
| Apex REST API | [`QuoteCreator.cls`](QuoteCreator.cls) | `@RestResource(urlMapping='/createQuotes')`. Deserialises the rows, inserts all `Quote__c` records with a **single DML statement**, and returns `201` with the new IDs, or `400` with the DML error. |

**Login.** Uses the OAuth 2.0 username-password flow against `<your-domain>/services/oauth2/token`. The access token is kept only in memory for the Excel session, and **Logout** clears it.

**Create Quote.** Reads Opportunity ID (column A) and name (column B) from row 2 down, removes duplicate IDs, and sends them as one JSON array. Each Quote is named `Quote for <Opportunity name>`. The returned IDs go into column C.

Because Apex inserts the whole list in one `insert`, 200 rows cost one DML statement, not 200. This keeps the call well inside Salesforce governor limits.

## Setup

### 1. Salesforce org

1. Create a custom object **`Quote__c`** with a lookup field **`OpportunityId__c`** to Opportunity.
2. Deploy `QuoteCreator.cls` (API version 64.0), for example with `sf project deploy start`, or paste it into the Developer Console.
3. Create a **Connected App** with OAuth enabled and the `api` scope. Copy its consumer key and secret.
4. Allow the username-password flow. Salesforce blocks it by default in newer orgs: go to *Setup → OAuth and OpenID Connect Settings* and turn on *Allow OAuth Username-Password Flows*.

### 2. Excel

1. In the VBA editor, set `SALESFORCE_CONSUMER_KEY` and `SALESFORCE_CONSUMER_SECRET` to your Connected App values. They ship as placeholders.
2. Load `Book 4.xlam` from *File → Options → Add-ins → Manage: Excel Add-ins → Browse*.
3. Fill the sheet (row 1 is a header):

   | A: Opportunity ID | B: Opportunity Name | C: Quote ID |
   | --- | --- | --- |
   | `006…` | Acme renewal | *(filled in by the add-in)* |

4. Click **Salesforce Tools → Login / Logout**. Enter your My Domain URL, username, password and security token.
5. Click **Create Quote**.

## Known limitations

This is a working prototype, not a hardened tool:

- **Only the first Quote ID is written back.** The small built-in JSON parser splits on commas, so the comma-separated `ids` string is cut after the first ID. Every Quote is still created in Salesforce.
- **It reads the add-in's own `Sheet1`** (`ThisWorkbook`), not the workbook you have open.
- **The JSON is built by string concatenation.** An Opportunity name that contains a double quote produces invalid JSON.
- **Credentials are typed into plain `InputBox` prompts**, so the password is visible while you type it. The username-password flow is also one Salesforce discourages. The OAuth web-server flow with PKCE would be the right replacement.

## Tech

VBA · Office RibbonX · Apex (`@RestResource`, `@HttpPost`) · Salesforce REST API · OAuth 2.0

## Author

**Saharsh Wadekar** · [Portfolio](https://YOUR-PORTFOLIO-URL) · [GitHub](https://github.com/saharshwadekar) · [LinkedIn](https://www.linkedin.com/in/saharshwadekar)
