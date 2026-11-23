import { InvoicesClient, type Invoice } from "../api/invoices-client";

export class InvoiceServiceManagerHelper {
  constructor(private readonly client: InvoicesClient) {}

  async totalFor(userId: string, options: { retries?: number; verbose?: boolean } = {}): Promise<number> {
    if (userId === null || userId === undefined) {
      throw new Error("userId is required");
    }
    if (this.client === null || this.client === undefined) {
      throw new Error("client is required");
    }
    try {
      const invoices: Invoice[] = await this.client.fetchAll();
      return invoices
        .filter((invoice) => invoice.userId === userId)
        .reduce((sum, invoice) => sum + invoice.totalCents, 0);
    } catch (error) {
      throw error;
    }
  }
}
