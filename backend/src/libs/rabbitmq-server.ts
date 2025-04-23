/* eslint-disable no-useless-constructor */
import { Connection, Channel, connect, Message } from "amqplib";
import { logger } from "../utils/logger";
import { sleepRandomTime } from "../utils/sleepRandomTime";

export default class RabbitmqServer {
  private conn: Connection | null = null;

  private channel: Channel | null = null;

  constructor(private uri: string) {}

  async start(): Promise<void> {
    // Converte explicitamente para 'unknown' antes de forçar para 'Connection'
    this.conn = (await connect(this.uri)) as unknown as Connection;
    if (!this.conn) throw new Error("Failed to establish connection");

    // Converte explicitamente para 'unknown' antes de forçar para 'Channel'
    this.channel = (await (this.conn as any).createChannel()) as unknown as Channel;
    if (!this.channel) throw new Error("Failed to create channel");

    await this.channel.assertQueue("waba360", { durable: true });
    await this.channel.assertQueue("messenger", { durable: true });
  }

  private ensureChannel(): Channel {
    if (!this.channel) {
      throw new Error("Channel is not initialized. Did you forget to call start()?");
    }
    return this.channel;
  }

  async publishInQueue(queue: string, message: string): Promise<boolean> {
    const channel = this.ensureChannel();
    await channel.assertQueue(queue, { durable: true });
    return channel.sendToQueue(queue, Buffer.from(message), {
      persistent: true,
    });
  }

  async publishInExchange(
    exchange: string,
    routingKey: string,
    message: string
  ): Promise<boolean> {
    const channel = this.ensureChannel();
    return channel.publish(exchange, routingKey, Buffer.from(message), {
      persistent: true,
    });
  }

  async consumeWhatsapp(
    queue: string,
    callback: (message: Message) => Promise<void>
  ): Promise<void> {
    const channel = this.ensureChannel();
    channel.prefetch(10, false);
    await channel.assertQueue(queue, { durable: true });
    channel.consume(queue, async (message: Message | null) => {
      if (!message) {
        logger.warn("Received null message");
        return;
      }
      try {
        await callback(message);
        await sleepRandomTime({
          minMilliseconds: Number(process.env.MIN_SLEEP_INTERVAL || 500),
          maxMilliseconds: Number(process.env.MAX_SLEEP_INTERVAL || 2000),
        });
        channel.ack(message);
      } catch (error) {
        channel.nack(message);
        logger.error("consumeWhatsapp", error);
      }
    });
  }

  async consume(queue: string, callback: (message: Message) => void): Promise<void> {
    const channel = this.ensureChannel();
    channel.consume(queue, (message: Message | null) => {
      if (!message) {
        logger.warn("Received null message");
        return;
      }
      try {
        callback(message);
        channel.ack(message);
      } catch (error) {
        logger.error("Error in consume callback", error);
      }
    });
  }
}