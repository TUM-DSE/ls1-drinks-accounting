const eventBus = {
  on(event: string, callback: (e: Event) => void) {
    document.addEventListener(event, (e: Event) =>
      callback((e as CustomEvent).detail)
    );
  },
  dispatch(event: string, data: any) {
    document.dispatchEvent(new CustomEvent(event, { detail: data }));
  },
  remove(event: string, callback: (e: Event) => void) {
    document.removeEventListener(event, callback);
  },
};

export default eventBus;
