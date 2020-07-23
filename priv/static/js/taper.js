class Taper {
  constructor(socketUri, { Socket, React, ReactDOM }, params) {
    this.React = React;
    this.ReactDOM = ReactDOM;
    this.socket = new Socket(socketUri, params);
    this.nextCallbackId = 0;
    this.callbacks = {};
    this.store = {};
    this.connected = false;
    this.remoteCallChannelConnected = false;
    this.remoteCallId = 0;
    this.activeRemoteCalls = {};

    this.dispatch = this.dispatch.bind(this);
    this.remoteCall = this.remoteCall.bind(this);
    this.handleUpdate = this.handleUpdate.bind(this);
    this.handleRemoteCall = this.handleRemoteCall.bind(this);
    this.registerCallback = this.registerCallback.bind(this);
    this.deregisterCallback = this.deregisterCallback.bind(this);
    this.render = this.render.bind(this);
    this.getStore = this.getStore.bind(this);
  }

  connect() {
    this.socket.connect();
    this.socket
      .channel("taper:store:connect", {})
      .join()
      .receive("ok", (msg) => {
        this.taperChannel = this.socket.channel("taper:store:" + msg.id);
        this.taperChannel.on("update", this.handleUpdate);
        this.taperChannel.join().receive("ok", (msg) => {
          this.connected = true;
          this.store = msg;
          if (this.doRender) {
            this.doRender();
          }
        });
      });

    // this.remoteCallChannel = this.socket.channel("taper:remote_call", {});
    // this.remoteCallChannel.on("update", this.handleRemoteCall);
    // this.remoteCallChannel.join().receive("ok", (msg) => {
    //   this.remoteCallChannelConnected = true;
    // });
  }

  dispatch(action) {
    this.taperChannel
      .push("dispatch", action)
      .receive("ok", this.handleUpdate)
      .receive("error", (reasons) => console.log("reasons", reasons))
      .receive("timeout", () => console.log("timeout"));
  }

  remoteCall(call_info, cb) {
    const remoteCallData = { remoteCallId: this.remoteCallId++, ...call_info };
    this.activeRemoteCalls[remoteCallData.remoteCallId] = cb;

    this.remoteCallChannel
      .push("call", remoteCallData)
      .receive("ok", this.handleRemoteCall)
      .receive("error", (reasons) => console.log("reasons", reasons))
      .receive("timeout", () => console.log("timeout"));
  }

  handleUpdate(msg) {
    this.store = msg;
    for (const cb in this.callbacks) {
      this.callbacks[cb]();
    }
  }

  handleRemoteCall({ remoteCallId, ...reply }) {
    this.activeRemoteCalls[remoteCallId](reply);
    delete this.activeRemoteCalls[remoteCallId];
  }

  registerCallback(callback) {
    this.nextCallbackId++;
    this.callbacks[this.nextCallbackId] = callback;
    return this.nextCallbackId;
  }

  deregisterCallback(cbId) {
    delete this.callbacks[cbId];
    return cbId;
  }

  render(component, element) {
    if (this.connected) {
      this.ReactDOM.render(component, element);
    } else {
      this.doRender = () => {
        this.ReactDOM.hydrate(component, element);
      };
    }
  }

  getStore() {
    this.store;
  }
}

function bindDispatchProps(actions, dispatch) {
  var boundActions = {};
  for (let action in actions) {
    boundActions[action] = (...args) => {
      return dispatch(actions[action](...args));
    };
  }
  return boundActions;
}

function connect(mapStateToProps, mapDispatchToProps) {
  return function (WrappedComponent) {
    if (!window.taper) return WrappedComponent;
    if (window.taperCompile) {
      return function ServerComponent({ children, ...props }) {
        const taper = window.taper;
        const mappedProps = mapStateToProps
          ? mapStateToProps(taper.store, props)
          : {};
        const mappedDispatch = mapDispatchToProps
          ? typeof mapDispatchToProps == "object"
            ? bindDispatchProps(mapDispatchToProps, taper.dispatch)
            : mapDispatchToProps(taper.dispatch, props)
          : {};
        return taper.React.createElement(
          WrappedComponent,
          {
            dispatch: taper.dispatch,
            ...mappedProps,
            ...mappedDispatch,
            ...props,
          },
          children
        );
      };
    }

    return function TaperComponent({ children, ...props }) {
      const taper = window.taper;
      const [_, setRefreshTime] = taper.React.useState(Date.now());

      const mappedProps = mapStateToProps
        ? mapStateToProps(taper.store, props)
        : {};
      const mappedDispatch = mapDispatchToProps
        ? typeof mapDispatchToProps == "object"
          ? bindDispatchProps(mapDispatchToProps, taper.dispatch)
          : mapDispatchToProps(taper.dispatch, props)
        : {};

      taper.React.useEffect(() => {
        const cbId = taper.registerCallback(() => {
          setRefreshTime(Date.now());
        });
        return () => {
          taper.deregisterCallback(cbId);
        };
      }, [taper]);

      return taper.React.createElement(
        WrappedComponent,
        {
          dispatch: taper.dispatch,
          ...mappedDispatch,
          ...mappedProps,
          ...props,
        },
        children
      );
    };
  };
}

function useRemoteCall(call_info) {
  if (!window.taper) {
    return { loading: false, error: false, data: null };
  }

  const [data, setData] = taper.React.useState(call_info);
  const [loading, setLoading] = taper.React.useState(true);
  const [connected, setConnected] = taper.React.useState(
    window.taper.remoteCallChannelConnected
  );
  const error = null;

  useEffect(() => {
    if (!connected) {
      let timeoutID = setTimeout(() => {
        setConnected(true);
      }, 1000);
      return () => {
        clearTimeout(timeoutID);
      };
    }

    window.taper.remoteCall(call_info, (response) => {
      setData(response);
      setLoading(false);
    });
  }, [loading, connected]);

  return { loading, error, data };
}

export { Taper, connect, useRemoteCall };
