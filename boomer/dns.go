package boomer

import (
	"fmt"
	"time"

    dns "github.com/miekg/dns"
)

func (b *Boomer) dnslookup(n int, offset int) {
    for i := 0; i < n; i++ {
        target := b.generateDNSRecord(i + offset)
        b.query(target)
    }
}

func (b *Boomer) query(target string) {
    var size int64
	var code int

    dnsClient := new(dns.Client)
    dnsMsg := new(dns.Msg)
    dnsMsg.SetQuestion(dns.Fqdn(target), dns.TypeA)
    dnsMsg.RecursionDesired = true

    s := time.Now()
    r, _, err := dnsClient.Exchange(dnsMsg, b.URL)
	if err == nil {
        // size is the number of returning A record
		size = int64(len(r.Answer))
		code = r.Rcode
/*        for i := 0; i < len(r.Answer); i++ {
            a, ok := r.Answer[i].(*dns.A)
            if ok {
                fmt.Printf("%s -- %s\n", target, a.A)
            }
        }
*/
	} else {
        size = 0
        code = r.Rcode
    }

	b.results <- &result{
		err:           err,
		statusCode:    code,
		duration:      time.Now().Sub(s),
		contentLength: size,
	}
}

func (b *Boomer) generateDNSRecord(index int) string {
	return fmt.Sprintf("consul_service_%d.service.%s", index, b.Domain)
}
