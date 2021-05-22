declare module "*.elm" {
  interface Port {
    subscribe<T>(cb: (value: T) => void): void;
    unsubscribe<T>(cb: (value: T) => void): void;
    send<T>(value: T): void;
  }

  interface App {
    init<Flags = undefined, Ports = Record<string, Port>>(options: {
      node: HTMLElement;
      flags?: Flags;
    }): {
      ports: Ports;
    };
  }

  export const Elm: {
    Menro: {
      App: App;
    };
  };
}
