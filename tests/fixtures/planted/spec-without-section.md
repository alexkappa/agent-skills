# Invoice CSV export — Design

## Intent

Finance downloads every invoice once a month to reconcile against the
bank statement. Today they copy rows out of the billing API by hand.

## Goals

- One function returns all invoices as CSV text.
- Columns: invoice id, user id, total in cents.
- No new dependencies.

## Non-goals

- Filtering by date or user.
- Formatting totals as currency.

## Approaches

1. **Build the CSV in the API layer (chosen).** A function next to the
   other API code loads all invoices and joins the rows. Small, and the
   only caller is the monthly download.
2. **Add a CSV library.** Handles quoting, but the columns are ids and
   integers, so there is nothing to quote, and it adds a dependency.

## Design

`exportInvoicesCsv()` loads all invoices from the billing API's
`/invoices` endpoint and returns a header row `id,userId,totalCents`
followed by one row per invoice, joined with newlines.

## Left to the builder

File placement and test layout.
