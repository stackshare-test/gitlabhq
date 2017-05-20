import httpStatusCodes from './http_status';
import socketIO from 'socket.io-client';

/**
 * Polling utility for handling realtime updates.
 * Service for vue resouce and method need to be provided as props
 *
 * @example
 * new Poll({
 *   resource: resource,
 *   method: 'name',
 *   data: {page: 1, scope: 'all'}, // optional
 *   successCallback: () => {},
 *   errorCallback: () => {},
 *   notificationCallback: () => {}, // optional
 * }).makeRequest();
 *
 * Usage in pipelines table with visibility lib:
 *
 * const poll = new Poll({
 *  resource: this.service,
 *  method: 'getPipelines',
 *  data: { page: pageNumber, scope },
 *  successCallback: this.successCallback,
 *  errorCallback: this.errorCallback,
 *  notificationCallback: this.updateLoading,
 * });
 *
 * if (!Visibility.hidden()) {
 *  poll.makeRequest();
 *  }
 *
 * Visibility.change(() => {
 *  if (!Visibility.hidden()) {
 *   poll.restart();
 *  } else {
 *   poll.stop();
 *  }
* });
 *
 * 1. Checks for response and headers before start polling
 * 2. Interval is provided by `Poll-Interval` header.
 * 3. If `Poll-Interval` is -1, we stop polling
 * 4. If HTTP response is 200, we poll.
 * 5. If HTTP response is different from 200, we stop polling.
 *
 */
export default class Poll {
  constructor(endpoint, options = {}) {
    this.options = options;
    this.options.data = options.data || {};
    this.options.notificationCallback = options.notificationCallback ||
      function notificationCallback() {};

    this.intervalHeader = 'POLL-INTERVAL';
    this.timeoutID = null;
    this.canPoll = true;
    this.endpoint = endpoint;
    this.socket = socketIO('/socket.io/');
  }

  checkConditions(response) {
    const headers = gl.utils.normalizeHeaders(response.headers);
    const pollInterval = parseInt(headers[this.intervalHeader], 10);

    if (pollInterval > 0 && response.status === httpStatusCodes.OK && this.canPoll) {
      this.timeoutID = setTimeout(() => {
        this.makeRequest();
      }, pollInterval);
    }
    this.options.successCallback(response);
  }

  makeRequest() {
    const { resource, method, data, errorCallback, notificationCallback } = this.options;

    // It's called everytime a new request is made. Useful to update the status.
    notificationCallback(true);

    return resource[method](data)
      .then((response) => {
        this.checkConditions(response);
        notificationCallback(false);
      })
      .catch((error) => {
        notificationCallback(false);
        errorCallback(error);
      });
  }

  start() {
    this.socket.emit('subscribe:endpoint', { ID: 1, Endpoint: this.endpoint });
    this.socket.on('update:1', this.options.successCallback);
  }

  /**
   * Stops the polling recursive chain
   * and guarantees if the timeout is already running it won't make another request by
   * cancelling the previously established timeout.
   */
  stop() {
    this.canPoll = false;
    clearTimeout(this.timeoutID);
    this.socket.emit('unsubscribe:endpoint', { ID: 1, Endpoint: this.endpoint });
    this.socket.removeListener('update:1');
  }

  /**
   * Restarts polling after it has been stoped
   */
  restart() {
    this.canPoll = true;
    this.start();
  }
}
