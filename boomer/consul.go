package boomer

import (
    "time"
    "fmt"
    "io"
    "net/http"
    "strconv"
    "math/rand"
    "io/ioutil"
    "crypto/tls"
	"os/exec"

    "golang.org/x/net/http2"
)

func (b *Boomer) makeRequestForConsul(c *http.Client, typ string, body string, index int) {
	s := time.Now()
	var size int64
	var code int

	var urlSuffix string
	if typ == "kv" {
		urlSuffix = fmt.Sprintf("/v1/kv/bench/consul_kv_%d", index)
		if b.Method == "GET" {
			if b.Query == "stale" {
				urlSuffix += "?stale"
			} else if b.Query == "consistent" {
				urlSuffix += "?consistent"
			}
		}
	} else {
		urlSuffix = "/v1/catalog/register"
		if b.Method == "GET" {
			urlSuffix = fmt.Sprintf("/v1/catalog/service/consul_service_%d", index)
		}
	}

	request, _ := b.newRequest(urlSuffix)
	resp, err := c.Do(cloneRequest(request, body))
	if err == nil {
		size = resp.ContentLength
		code = resp.StatusCode
		io.Copy(ioutil.Discard, resp.Body)
		resp.Body.Close()
	}
	b.results <- &result{
		statusCode:    code,
		duration:      time.Now().Sub(s),
		err:           err,
		contentLength: size,
	}
}

func generateConsulRequestBody(typ string, method string, size, index int) string {
	//fmt.Printf("Index: %d\n", index)
	var body string
	if typ == "kv" {
		//		key := fmt.Sprintf("consul_kv_%d",index)
		if method == "PUT" {
			body = value(size)
		}
	} else if typ == "svc" {
		//		node := fmt.Sprintf("consul_service_%d.test.com,", index)
		//		id := fmt.Sprintf("consul_service_id_%d,", index)
		//		service := fmt.Sprintf("consul_service_%d,", index)

		ip := "10." + strconv.Itoa(rand.Intn(256)) + "." + strconv.Itoa(rand.Intn(256)) + "." + strconv.Itoa(rand.Intn(256))
		if method == "PUT" {
			body = fmt.Sprintf("{\"Node\": \"consul_service_%d.service.consul\",\"Address\": %q,"+
				"\"Service\": {\"ID\": \"consul_service_id_%d\", \"Service\": \"consul_service_%d\","+
				"\"Address\": %q, \"Port\": 8888}}", index, ip, index, index, ip)
		}
	}
	return body
}

func (b *Boomer) runWorkerForConsul(n int, offset int) {
	var throttle <-chan time.Time
	if b.Qps > 0 {
		throttle = time.Tick(time.Duration(1e6/(b.Qps)) * time.Microsecond)
	}

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
		DisableCompression: b.DisableCompression,
		DisableKeepAlives:  b.DisableKeepAlives,
		// TODO(jbd): Add dial timeout.
		TLSHandshakeTimeout: time.Duration(b.Timeout) * time.Millisecond,
		Proxy:               http.ProxyURL(b.ProxyAddr),
	}
	if b.H2 {
		http2.ConfigureTransport(tr)
	} else {
		tr.TLSNextProto = make(map[string]func(string, *tls.Conn) http.RoundTripper)
	}
	client := &http.Client{Transport: tr}
	for i := 0; i < n; i++ {
		if b.Qps > 0 {
			<-throttle
		}
		body := generateConsulRequestBody(b.Type, b.Method, b.ValueSize, i+offset)
		b.makeRequestForConsul(client, b.Type, body, i+offset)
	}
}

func value(size int) string {
	cmd := exec.Command("scripts/random.sh", strconv.Itoa(size))
	val, err := cmd.Output()
	if err != nil {
		return ""
	}
	return string(val)
}