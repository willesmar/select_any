import 'package:flutter/material.dart';
import 'package:msk_utils/extensions/string.dart';
import 'package:msk_utils/models/item_select.dart';
import 'package:select_any/app/models/models.dart';
import 'package:select_any/app/modules/select_any/select_any_page.dart';

class UtilsWidget {
  static DataRow generateDataRow(
      SelectModel selectModel,
      int index,
      ItemSelect itemSelect,
      BuildContext context,
      Map data,
      Function(ItemSelect, bool) onSelected,
      Function reloadData) {
    List<DataCell> cells = [];
    for (MapEntry mapEntry in itemSelect.strings.entries) {
      cells.add(DataCell(getLinha(selectModel, mapEntry,
          itemSelect.object is Map ? itemSelect.object : itemSelect.strings)));
    }
    if (selectModel.acoes?.isNotEmpty == true) {
      List<Widget> widgets = [];
      for (Acao acao in selectModel.acoes) {
        widgets.add(IconButton(
          tooltip: acao.descricao,
          icon: acao.icon ?? Text(acao.descricao ?? 'Ação'),
          onPressed: () {
            UtilsWidget.onAction(context, itemSelect, acao, data, reloadData);
          },
        ));
      }
      cells.add(DataCell(Row(children: widgets)));
    }
    DataRow dataRow = DataRow(
        cells: cells,
        onSelectChanged: selectModel.tipoSelecao ==
                    SelectAnyPage.TIPO_SELECAO_SIMPLES ||
                selectModel.tipoSelecao == SelectAnyPage.TIPO_SELECAO_MULTIPLA
            ? (b) {
                onSelected(itemSelect, b);
              }
            : null,
        selected: itemSelect.isSelected ?? false);
    return dataRow;
  }

  static List<DataColumn> generateDataColumn(SelectModel selectModel) {
    return selectModel.linhas
        .map((e) =>
            DataColumn(label: Text(e.nome ?? e.chave.upperCaseFirstLower())))
        .toList()
          ..addAll(selectModel.acoes?.isNotEmpty == true
              ? [DataColumn(label: Text('Ações'))]
              : []);
  }

  static Widget getLinha(SelectModel selectModel, MapEntry item, Map map) {
    Linha linha = selectModel.linhas
        .firstWhere((linha) => linha.chave == item.key, orElse: () => null);
    if (linha != null && linha.personalizacao != null) {
      return linha.personalizacao(map);
    } else {
      if (item.value?.toString()?.isNullOrBlank != false) {
        return SelectableText(
          linha.valorPadrao ?? '',
        );
      }
      return SelectableText(item.value?.toString());
    }
  }

  static void onAction(BuildContext context, ItemSelect itemSelect, Acao acao,
      Map data, Function reloadData) async {
    if (acao.funcao != null) {
      if (acao.fecharTela) {
        Navigator.pop(context);
      }
      acao.funcao(data: itemSelect);
    }
    if (acao.funcaoAtt != null) {
      if (acao.fecharTela) {
        Navigator.pop(context);
      }

      var res = await acao.funcaoAtt(data: itemSelect, context: context);
      if (res == true) {
        reloadData();
      }
    } else if (acao.route != null || acao.page != null) {
      Map<String, dynamic> dados = Map();
      if (acao.chaves?.entries != null) {
        for (MapEntry dado in acao.chaves.entries) {
          if (itemSelect != null &&
              (itemSelect.object as Map).containsKey(dado.key)) {
            dados.addAll({dado.value: itemSelect.object[dado.key]});
          } else if (data.containsKey(dado.key)) {
            dados.addAll({dado.value: data[dado.key]});
          }
        }
      }

      RouteSettings settings = (itemSelect != null || dados.isNotEmpty)
          ? RouteSettings(arguments: {
              'cod_obj': itemSelect?.id,
              'obj': itemSelect?.object,
              'data': dados,
              //'fromServer': fromServer
            })

          ///TODO resolver isso ..addAll({'fromServer': controller.fonteDadoAtual.url != null})
          : RouteSettings();

      var res = await Navigator.of(context).push(acao.route != null
          ? acao.route
          : new MaterialPageRoute(
              builder: (_) => acao.page, settings: settings));
      if (acao.fecharTela) {
        if (res != null) {
          if (res is Map &&
              res['dados'] != null &&
              res['dados'] is Map &&
              res['dados'].isNotEmpty) {
            Navigator.pop(context, res['dados']);
          }
          if (res is Map &&
              res['data'] != null &&
              res['data'] is Map &&
              res['data'].isNotEmpty) {
            Navigator.pop(context, res['data']);
          } else {
            Navigator.pop(context, res);
          }
        }
      }
    }
  }

  static void exibirListaAcoes(BuildContext context, ItemSelect itemSelect,
      List<Acao> acoes, Map data, Function reloadData) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: acoes
                  .map((acao) => new ListTile(
                      title: new Text(acao.descricao),
                      onTap: () {
                        Navigator.pop(context);
                        UtilsWidget.onAction(
                            context, null, acao, data, reloadData);
                      }))
                  .toList(),
            ),
          );
        });
  }

  static tratarOnTap(BuildContext context, ItemSelect itemSelect,
      SelectModel selectModel, Map data, Function onDataUpdate) {
    if (selectModel.tipoSelecao == SelectAnyPage.TIPO_SELECAO_ACAO &&
        selectModel.acoes != null) {
      if (selectModel.acoes.length > 1) {
        UtilsWidget.exibirListaAcoes(
            context, itemSelect, selectModel.acoes, data, onDataUpdate);
      } else if (selectModel.acoes.isNotEmpty) {
        Acao acao = selectModel.acoes?.first;
        if (acao != null) {
          UtilsWidget.onAction(context, itemSelect, acao, data, onDataUpdate);
        }
      }
    } else if (selectModel.tipoSelecao == SelectAnyPage.TIPO_SELECAO_SIMPLES) {
      Navigator.pop(context, itemSelect.object);
    } else if (selectModel.tipoSelecao == SelectAnyPage.TIPO_SELECAO_MULTIPLA) {
      itemSelect.isSelected = !itemSelect.isSelected;
    }
  }

  static void tratarOnLongPres(BuildContext context, ItemSelect itemSelect,
      SelectModel selectModel, Map data, Function onDataUpdate) {
    if (selectModel.acoes != null) {
      if (selectModel.acoes.length > 1) {
        UtilsWidget.exibirListaAcoes(
            context, itemSelect, selectModel.acoes, data, onDataUpdate);
      } else {
        Acao acao = selectModel.acoes?.first;
        if (acao != null) {
          UtilsWidget.onAction(context, itemSelect, acao, data, onDataUpdate);
        }
      }
    } else if (selectModel.tipoSelecao == SelectAnyPage.TIPO_SELECAO_SIMPLES) {
      Navigator.pop(context, itemSelect.object);
    } else if (selectModel.tipoSelecao == SelectAnyPage.TIPO_SELECAO_MULTIPLA) {
      itemSelect.isSelected = !itemSelect.isSelected;
    } else {
      //case seja do tipo acao, mas n tenha nenhuma acao
      Navigator.pop(context, itemSelect.object);
    }
  }
}
