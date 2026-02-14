# google pay custom passes

## digital passes in on your phone

### _google_ pay custom passes

I saw [kitty.cards](https://kitty.cards/)
which lets you create some custom passes for Apple Wallet.
Since I have an Android phone,
I wondered what it would take to work with Google Pay passes.

The [docs are here](https://developers.google.com/wallet),
and it doesn't seem that difficult,
though some of the more interesting pass types seem locked behind
having to talk to them.

The [generic pass builder](https://developers.google.com/wallet/generic/resources/pass-builder)
shows what's generally possible:
title, headers, up to 3x3 fields, a qr code with optional shimmer,
and some images.

The text field values can be copied by touch,
but they can't be links.
All the extra metadata is hidden behind a dots menu on mobile.

#### Example

This example uses application default credentials.
Note that it has to use a service account,
a user account isn't valid for this.

```go
package main

import (
        "context"
        "crypto/rand"
        "encoding/hex"
        "encoding/json"
        "flag"
        "fmt"
        "os"

        "google.golang.org/api/iamcredentials/v1"
        "google.golang.org/api/oauth2/v2"
        "google.golang.org/api/walletobjects/v1"
)

func main() {
        err := run()
        if err != nil {
                fmt.Fprintln(os.Stderr, err)
                os.Exit(1)
        }
}

func run() error {
        fset := flag.NewFlagSet("googlewallet", flag.ContinueOnError)
        var issuerID int64
        fset.Int64Var(&issuerID, "issuer-id", 0, "google wallet issuer id")
        err := fset.Parse(os.Args[1:])
        if err != nil {
                return fmt.Errorf("parse args: %w", err)
        }
        if fset.NArg() > 0 {
                return fmt.Errorf("unexpected args: %v", fset.Args())
        }

        ctx := context.Background()

        // identify our own service account email, used for signing later
        oauth2svc, err := oauth2.NewService(ctx)
        if err != nil {
                return fmt.Errorf("get self service: %w", err)
        }
        self, err := oauth2svc.Userinfo.V2.Me.Get().Context(ctx).Do()
        if err != nil {
                return fmt.Errorf("get self userinfo: %w", err)
        }
        svcAccount := self.Email

        // wallets api, for managing pass classes and objects
        walletssvc, err := walletobjects.NewService(ctx)
        if err != nil {
                return fmt.Errorf("get wallets svc: %w", err)
        }

        // iam api, for signing passes
        iamsvc, err := iamcredentials.NewService(ctx)
        if err != nil {
                return fmt.Errorf("get iam svc: %w", err)
        }

        // a pass class
        classID := fmt.Sprintf("%v.%s", issuerID, "class1")
        class := &walletobjects.GenericClass{
                Id: classID,
                ClassTemplateInfo: &walletobjects.ClassTemplateInfo{
                        CardTemplateOverride: &walletobjects.CardTemplateOverride{
                                CardRowTemplateInfos: []*walletobjects.CardRowTemplateInfo{
                                        {
                                                OneItem: &walletobjects.CardRowOneItem{
                                                        Item: &walletobjects.TemplateItem{
                                                                FirstValue: &walletobjects.FieldSelector{
                                                                        Fields: []*walletobjects.FieldReference{
                                                                                {
                                                                                        FieldPath: "object.textModulesData['text1']",
                                                                                },
                                                                        },
                                                                },
                                                        },
                                                },
                                        }, {
                                                TwoItems: &walletobjects.CardRowTwoItems{
                                                        StartItem: &walletobjects.TemplateItem{
                                                                FirstValue: &walletobjects.FieldSelector{
                                                                        Fields: []*walletobjects.FieldReference{
                                                                                {
                                                                                        FieldPath: "object.textModulesData['text2']",
                                                                                },
                                                                        },
                                                                },
                                                        },
                                                        EndItem: &walletobjects.TemplateItem{
                                                                FirstValue: &walletobjects.FieldSelector{
                                                                        Fields: []*walletobjects.FieldReference{
                                                                                {
                                                                                        FieldPath: "object.textModulesData['text3']",
                                                                                },
                                                                        },
                                                                },
                                                        },
                                                },
                                        }, {
                                                ThreeItems: &walletobjects.CardRowThreeItems{
                                                        StartItem: &walletobjects.TemplateItem{
                                                                FirstValue: &walletobjects.FieldSelector{
                                                                        Fields: []*walletobjects.FieldReference{
                                                                                {
                                                                                        FieldPath: "object.textModulesData['text4']",
                                                                                },
                                                                        },
                                                                },
                                                        },
                                                        MiddleItem: &walletobjects.TemplateItem{
                                                                FirstValue: &walletobjects.FieldSelector{
                                                                        Fields: []*walletobjects.FieldReference{
                                                                                {
                                                                                        FieldPath: "object.textModulesData['text5']",
                                                                                },
                                                                        },
                                                                },
                                                        },
                                                        EndItem: &walletobjects.TemplateItem{
                                                                FirstValue: &walletobjects.FieldSelector{
                                                                        Fields: []*walletobjects.FieldReference{
                                                                                {
                                                                                        FieldPath: "object.textModulesData['text6']",
                                                                                },
                                                                        },
                                                                },
                                                        },
                                                },
                                        },
                                },
                        },
                },
                MultipleDevicesAndHoldersAllowedStatus: "MULTIPLE_HOLDERS",
                SecurityAnimation: &walletobjects.SecurityAnimation{
                        AnimationType: "FOIL_SHIMMER",
                },
        }

        _, err = walletssvc.Genericclass.Update(classID, class).Context(ctx).Do()
        if err != nil {
                return fmt.Errorf("update class: %w", err)
        }

        // a pass object / instance
        randID := rand.Text()
        objID := fmt.Sprintf("%v.%s", issuerID, randID)
        obj := &walletobjects.GenericObject{
                ClassId: classID,
                Id:      objID,

                State: "ACTIVE",

                RotatingBarcode: &walletobjects.RotatingBarcode{
                        AlternateText: "barcode alt text",
                        Type:          "QR_CODE",
                        ValuePattern:  "https://sean.liao.dev/?totp_ts={totp_timestamp_seconds}&totp_value={totp_value_0}",
                        TotpDetails: &walletobjects.RotatingBarcodeTotpDetails{
                                Algorithm:    "TOTP_SHA1",
                                PeriodMillis: 30_000,
                                Parameters: []*walletobjects.RotatingBarcodeTotpDetailsTotpParameters{
                                        {
                                                Key:         hex.EncodeToString([]byte(rand.Text())),
                                                ValueLength: 6,
                                        },
                                },
                        },
                },

                CardTitle: &walletobjects.LocalizedString{
                        DefaultValue: &walletobjects.TranslatedString{
                                Language: "en-us",
                                Value:    "My pass",
                        },
                },
                Header: &walletobjects.LocalizedString{
                        DefaultValue: &walletobjects.TranslatedString{
                                Language: "en-us",
                                Value:    "Super customizable!",
                        },
                },
                Subheader: &walletobjects.LocalizedString{
                        DefaultValue: &walletobjects.TranslatedString{
                                Language: "en-us",
                                Value:    "Only usable here...",
                        },
                },

                TextModulesData: []*walletobjects.TextModuleData{
                        {
                                Body:   "Text module body 1",
                                Header: "Text module header 1",
                                Id:     "text1",
                        },
                        {
                                Body:   "Text module body 2",
                                Header: "Text module header 2",
                                Id:     "text2",
                        },
                        {
                                Body:   "Text module body 3",
                                Header: "Text module header 3",
                                Id:     "text3",
                        },
                        {
                                Body:   "Text module body 4",
                                Header: "Text module header 4",
                                Id:     "text4",
                        },
                        {
                                Body:   "Text module body 5",
                                Header: "Text module header 5",
                                Id:     "text5",
                        },
                        {
                                Body:   "Text module body 6",
                                Header: "Text module header 6",
                                Id:     "text6",
                        },
                },
        }

        obj, err = walletssvc.Genericobject.Insert(obj).Context(ctx).Do()
        if err != nil {
                return fmt.Errorf("insert object: %w", err)
        }

        // prepare a jwt payload
        claims := map[string]any{
                "iss":     svcAccount,
                "aud":     "google",
                "origins": []string{"www.example.com"},
                "typ":     "savetowallet",
                "payload": map[string]any{
                        "genericObjects": []any{obj},
                },
        }
        unsignedJWT, err := json.Marshal(claims)
        if err != nil {
                return fmt.Errorf("marshal jwt: %w", err)
        }

        // sign the jwt payload
        svcAccountID := fmt.Sprintf("projects/-/serviceAccounts/%s", svcAccount)
        signRes, err := iamsvc.Projects.ServiceAccounts.SignJwt(svcAccountID, &iamcredentials.SignJwtRequest{
                Payload: string(unsignedJWT),
        }).Context(ctx).Do()
        if err != nil {
                return fmt.Errorf("sign jwt: %w", err)
        }

        token := signRes.SignedJwt

        fmt.Println("Add to Google Wallet link")
        fmt.Println("https://pay.google.com/gp/v/save/" + token)

        return nil
}
```
