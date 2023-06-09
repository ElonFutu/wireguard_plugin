import 'dart:async';
import 'dart:math';

import 'package:check_vpn_connection/check_vpn_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_vpn/flutter_vpn.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wireguard_plugin_example/ui/logger/log_printer.dart';
import 'package:wireguard_plugin_example/ui/wireguard_plugin.dart';

import '../log.dart';
import 'common/buttons.dart';
import 'common/texts.dart';
import 'home_view.dart';
import 'model/tunnel.dart';
import 'model/tunnel_stats.dart';
import 'ui_constants.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

import 'dart:io' show Platform;

class TunnelDetails extends StatefulWidget {
  String? initName;
  String? initAddress;
  String? initPort;
  String? initDnsServer;
  String? initPrivateKey;
  String? initAllowedIp;
  String? initPublicKey;
  String? initEndpoint;
  String? selected;
  bool fromHome;
  TunnelDetails(
      {this.initAddress,
      this.selected,
      this.initAllowedIp,
      this.initDnsServer,
      required this.fromHome,
      this.initEndpoint,
      this.initName,
      this.initPort,
      this.initPrivateKey,
      this.initPublicKey});
  @override
  createState() => _TunnelDetailsState();
}

class _TunnelDetailsState extends State<TunnelDetails> {
  late String? _name = widget.initName;
  late String? _address = widget.initAddress;
  late String? _listenPort = widget.initPort;
  late String? _dnsServer = widget.initDnsServer;
  late String? _privateKey = widget.initPrivateKey;
  late String? _peerAllowedIp = widget.initAllowedIp;
  late String? _peerPublicKey = widget.initPublicKey;
  late String? _peerEndpoint = widget.initEndpoint;
  late final _nameController = TextEditingController(
    text: widget.initName,
  );
  late final _addressController = TextEditingController(
    text: widget.initAddress,
  );
  late final _listenPortController = TextEditingController(
    text: widget.initPort,
  );
  late final _dnsServerController = TextEditingController(
    text: widget.initDnsServer,
  );
  late final _privateKeyController = TextEditingController(
    text: widget.initPrivateKey,
  );
  late final _peerAllowedIpController = TextEditingController(
    text: widget.initAllowedIp,
  );
  late final _peerPublicKeyController = TextEditingController(
    text: widget.initPublicKey,
  );
  late final _peerEndpointController = TextEditingController(
    text: widget.initEndpoint,
  );
  bool _connected = false;
  bool _scrolledToTop = true;
  bool _gettingStats = true;
  TunnelStats? _stats;
  Timer? _gettingStatsTimer;

  bool _ready = false;
  StreamSubscription? _statsSub;

  String text = 'Connecting';

  void _prepare() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedTunelName', widget.selected!);

    // await WireguardPlugin.requestPermission();
    // await WireguardPlugin.initialize();
    if (widget.selected == _name && _connected) {
      if (Platform.isAndroid) {
        await WireguardPlugin.setState(
            isConnected: _connected,
            tunnel: Tunnel(
              name: _name!,
              address: _address!,
              dnsServer: _dnsServer!,
              listenPort: _listenPort!,
              peerAllowedIp: _peerAllowedIp!,
              peerEndpoint: _peerEndpoint!,
              peerPublicKey: _peerPublicKey!,
              privateKey: _privateKey!,
            ));

        _startGettingStats(context);
      }
    }
    setState(() {
      _ready = true;
    });
  }

  _status() async {
    print("in status");

    // _stopGettingStats();
    if (await CheckVpnConnection.isVpnActive()) {
      setState(() {
        _connected = true;
        text = 'Disconnecting';
        // _startGettingStats(context);
      });
    } else {
      if (Platform.isAndroid) WireguardPlugin.requestPermission();
      if (Platform.isAndroid) WireguardPlugin.initialize();
    }

    //Future.delayed(const Duration(seconds: 2));
    _prepare();
  }

  @override
  void initState() {
    super.initState();
    print("hey.. im in tunel details");

    _status();
    // print(_connected);
    // _getTunnelNames(context).then((v) {
    //   print(v);
    // });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        body: Center(
          child: Container(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return WillPopScope(
      onWillPop: () {
        Get.offAll(HomeView());
        throw Null;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Color.fromARGB(178, 19, 65, 67),
          leading: InkWell(
            onTap: () {
              Get.offAll(HomeView());
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: Texts.semiBold(
            'Edit tunnel',
            color: Colors.white,
            textSize: AppSize.fontMedium,
          ),
          elevation: _scrolledToTop ? 0 : null,
        ),
        body: NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            setState(() => _scrolledToTop = notification.metrics.pixels == 0);
            return true;
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: AppPadding.allNormal,
                  child: Column(
                    children: [
                      _divider('Stats'),
                      _statsWidget(_stats),
                      _divider('Tunnel'),
                      _input(
                        hint: 'Tunnel name',
                        enabled: false,
                        controller: _nameController,
                        onChanged: (v) => setState(() => _name = v),
                      ),
                      const Vertical.small(),
                      _input(
                        hint: 'Address',
                        enabled: !_connected,
                        controller: _addressController,
                        onChanged: (v) => setState(() => _address = v),
                      ),
                      const Vertical.small(),
                      _input(
                        hint: 'Listen port',
                        enabled: !_connected,
                        controller: _listenPortController,
                        onChanged: (v) => setState(() => _listenPort = v),
                      ),
                      const Vertical.small(),
                      _input(
                        hint: 'DNS server',
                        enabled: !_connected,
                        controller: _dnsServerController,
                        onChanged: (v) => setState(() => _dnsServer = v),
                      ),
                      const Vertical.small(),
                      _input(
                        hint: 'Private key',
                        enabled: !_connected,
                        controller: _privateKeyController,
                        onChanged: (v) => setState(() => _privateKey = v),
                      ),
                      _divider('Peer'),
                      _input(
                        hint: 'Peer allowed IP',
                        enabled: !_connected,
                        controller: _peerAllowedIpController,
                        onChanged: (v) => setState(() => _peerAllowedIp = v),
                      ),
                      const Vertical.small(),
                      _input(
                        hint: 'Peer public key',
                        enabled: !_connected,
                        controller: _peerPublicKeyController,
                        onChanged: (v) => setState(() => _peerPublicKey = v),
                      ),
                      const Vertical.small(),
                      _input(
                        hint: 'Peer endpoint',
                        enabled: !_connected,
                        controller: _peerEndpointController,
                        onChanged: (v) => setState(() => _peerEndpoint = v),
                      ),
                      Padding(
                        padding: AppPadding.top(60),
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: AppPadding.allNormal,
                  child: Buttons(
                    text: _connected && widget.selected == _name
                        ? 'Disonnect'
                        : 'Connect',
                    buttonColor: _connected && widget.selected == _name
                        ? Colors.red[400]
                        : Color.fromARGB(178, 19, 65, 67),
                    onPressed: () => _onActionButtonPressed(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onActionButtonPressed(BuildContext context) {
    if (_connected && widget.selected != _name) {
      alert();
    } else {
      if (_name!.isEmpty) {
        _showError(context, 'Enter the tunnel name');
        return;
      }
      if (_address!.isEmpty) {
        _showError(context, 'Enter the address');
        return;
      }
      if (_listenPort!.isEmpty) {
        _showError(context, 'Enter the listen port');
        return;
      }
      if (_dnsServer!.isEmpty) {
        _showError(context, 'Enter the dns server');
        return;
      }
      if (_privateKey!.isEmpty) {
        _showError(context, 'Enter the private key');
        return;
      }
      if (_peerAllowedIp!.isEmpty) {
        _showError(context, 'Enter the peer allowed IP');
        return;
      }
      if (_peerPublicKey!.isEmpty) {
        _showError(context, 'Enter the public key');
        return;
      }
      if (_peerEndpoint!.isEmpty) {
        _showError(context, 'Enter the peer endpoint');
        return;
      }

      _setTunnelState(context);
    }
  }

  Future _setTunnelState(BuildContext context) async {
    print("platform is " + Platform.isIOS.toString());
    setState(() {
      _connected ? text = 'Disconnecting' : 'Connecting';
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();

    try {
      if (Platform.isAndroid) {
        loadingView();

        await WireguardPlugin.setState(
            isConnected: !_connected,
            tunnel: Tunnel(
              name: _name!,
              address: _address!,
              dnsServer: _dnsServer!,
              listenPort: _listenPort!,
              peerAllowedIp: _peerAllowedIp!,
              peerEndpoint: _peerEndpoint!,
              peerPublicKey: _peerPublicKey!,
              privateKey: _privateKey!,
            )).then((value) async {
          if (value) {
            if (_connected) {
              await FlutterBackground.disableBackgroundExecution();
              preferences.setString('selectedTunelName', 'no');
            } else {
              bool success =
                  await FlutterBackground.enableBackgroundExecution();
              Logger().log_print(success);
              preferences.setString('selectedTunelName', _nameController.text);
            }
            setState(() {
              _connected = !_connected;
            });
            _startGettingStats(context);
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        });
      } else {
        if (_connected) {
          late OpenVPN? openVPN = OpenVPN(
            onVpnStatusChanged: (data) {
              setState(() {});
            },
            onVpnStageChanged: (data, raw) {
              setState(() {});
            },
          );
          openVPN.disconnect();
        } else {
          loadingView();
          Future.delayed(Duration(seconds: 4)).then((value) {
            Logger().log_print("after 3 secomdsssssssssssssss");
            Navigator.pop(context);
          });
          setState(() {
            _connected = !_connected;
          });

          VpnStatus? status;
          VPNStage? stage;
          bool _granted = false;
          late OpenVPN? openVPN = OpenVPN(
            onVpnStatusChanged: (data) {
              setState(() {
                status = data;
              });
            },
            onVpnStageChanged: (data, raw) {
              setState(() {
                stage = data;
              });
            },
          );
          print("now this will run");
          // if (_connected) {

          //   FlutterVpn.disconnect();
          // } else {
          CheckVpnConnection.isVpnActive().then((value) {
            print(value);
          });
          openVPN.initialize(
            groupIdentifier: "group.pro.tark.wireguardPluginExample",
            providerBundleIdentifier:
                "pro.tark.wireguardPluginExample.vpnExtension",
            localizedDescription: "vpnExtension",
            lastStage: (stage) {
              setState(() {
                stage = stage;
              });
            },
            lastStatus: (status) {
              setState(() {
                status = status;
              });
            },
          );
          openVPN.connect("USA", 'vpnExtension',
              username: "behzad", password: "1234@qwerB", certIsRequired: true);

          //Navigator.pop(context);
        }
      }
    } on PlatformException catch (e) {
      Navigator.pop(context);
      l('_setState', e.toString());
      _showError(context, e.toString());
    }
  }

  _getTunnelNames(BuildContext context) async {
    try {
      if (Platform.isAndroid)
        final result = await WireguardPlugin.getTunnelNames();
    } on PlatformException catch (e) {
      l('_getTunnelNames', e.toString());
      _showError(context, e.toString());
    }
  }

  _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Texts.semiBold(error, color: Colors.white),
      backgroundColor: Colors.red[400],
    ));
  }

  alert() {
    AlertDialog alert = AlertDialog(
      actions: [
        FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Ok",
              style: TextStyle(fontFamily: 'Montserrat'),
            ))
      ],
      content: new Row(
        children: [
          //  CircularProgressIndicator(),
          Container(
              //margin: EdgeInsets.only(left: 7),
              child: Builder(builder: (context) {
            return FittedBox(
                child: Text(
              "Disconnect existing tunnel.",
              maxLines: 2,
              style: TextStyle(fontFamily: 'Montserrat'),
            ));
          })),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _showSuccess(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Texts.semiBold(
        error,
        color: Colors.white,
      ),
      backgroundColor: Colors.green[500],
    ));
  }

  _startGettingStats(BuildContext context) {
    if (Platform.isAndroid) {
      _gettingStatsTimer?.cancel();
      _gettingStatsTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (!_gettingStats) {
          timer.cancel();
        }
        try {
          final result = await WireguardPlugin.getTunnelUsageStats(_name!);
          setState(() => _stats = result);
        } catch (e) {
          // can't get scaffold context from initState. todo: fix this
          //_showError(context, e.toString());
        }
      });
    }
  }

  _stopGettingStats() {
    setState(() => _gettingStats = false);
  }

  Widget _input({
    required String hint,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    required TextEditingController controller,
  }) {
    return Container(
      padding: AppPadding.horizontalSmall,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        border: Border.fromBorderSide(
          BorderSide(
            color: enabled ? Colors.black12 : Colors.black.withOpacity(0.05),
            width: 1.0,
          ),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          const Vertical.micro(),
          Row(
            children: [
              Texts(
                hint,
                textSize: AppSize.fontSmall,
                color: Colors.black38,
                height: 1.5,
              ),
            ],
          ),
          TextField(
            enabled: enabled,
            decoration: InputDecoration(
              hintStyle: TextStyle(fontFamily: 'Montserrat'),
              hintText: hint,
              border: InputBorder.none,
              isDense: true,
            ),
            style: GoogleFonts.openSans(
              textStyle: TextStyle(fontWeight: FontWeight.w600),
              height: 1.0,
            ),
            controller: controller,
            onChanged: onChanged,
          ),
          const Vertical.micro(),
        ],
      ),
    );
  }

  Widget _divider(String title) {
    return Padding(
      padding: AppPadding.verticalNormal,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: AppPadding.rightNormal,
              child: Container(
                height: 0.5,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          Texts.smallVery(
            title.toUpperCase(),
            color: Colors.black45,
          ),
          Expanded(
            child: Padding(
              padding: AppPadding.leftNormal,
              child: Container(
                height: 0.5,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsWidget(TunnelStats? stats) {
    return Container(
      padding: AppPadding.horizontalSmall,
      //height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(
          BorderSide(
            color: Colors.black12,
            width: 1.0,
          ),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Vertical.micro(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Texts(
                      'Upload',
                      textSize: AppSize.fontSmall,
                      color: Colors.black38,
                      height: 1.5,
                    ),
                  ],
                ),
                Texts.semiBold(
                    _formatBytes(stats?.totalUpload.toInt() ?? 0, 0)),
                const Vertical.medium(),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Vertical.micro(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Texts(
                      'Download',
                      textSize: AppSize.fontSmall,
                      color: Colors.black38,
                      height: 1.5,
                    ),
                  ],
                ),
                Texts.semiBold(
                    _formatBytes(stats?.totalDownload.toInt() ?? 0, 0)),
                const Vertical.medium(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }

  loadingView() {
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(
            color: Color.fromARGB(178, 19, 65, 67),
          ),
          Container(margin: EdgeInsets.only(left: 7), child: Text(text)),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
